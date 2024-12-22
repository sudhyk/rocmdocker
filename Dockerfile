################################################################################
# A runtime environment for https://github.com/comfyanonymous/ComfyUI
# With ROCm for AMD GPU.
################################################################################

FROM opensuse/tumbleweed:latest

# Note: GCC for InsightFace;
#       FFmpeg for video (pip[imageio-ffmpeg] will use system FFmpeg instead of bundled);
#       'half' for ORT on ROCm.
# Note: CMake may use different version of Python. Using 'update-alternatives' to ensure default version.
RUN --mount=type=cache,target=/var/cache/zypp \
    set -eu \
    && zypper addrepo --check --refresh --priority 90 \
    'https://ftp.gwdg.de/pub/linux/misc/packman/suse/openSUSE_Tumbleweed/Essentials/' packman-essentials \
    && zypper --gpg-auto-import-keys \
    install --no-confirm \
    python310 python310-pip python310-wheel python310-setuptools \
    python310-devel python310-Cython gcc-c++ python310-py-build-cmake \
    python310-numpy1 python310-opencv \
    python310-ffmpeg-python ffmpeg x264 x265 \
    python310-dbm \
    ghc-half \
    google-noto-sans-fonts google-noto-sans-cjk-fonts google-noto-coloremoji-fonts \
    shadow git aria2 \
    Mesa-libGL1 libgthread-2_0-0 \
    && rm -f /usr/lib64/python3.10/EXTERNALLY-MANAGED \
    && update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.10 10

RUN --mount=type=cache,target=/root/.cache/pip \
    pip install --break-system-packages \
    --upgrade pip wheel setuptools

# Install PyTorch && ONNX from AMD repo
# https://rocm.docs.amd.com/projects/radeon/en/latest/docs/install/native_linux/install-pytorch.html
# https://rocm.docs.amd.com/projects/radeon/en/latest/docs/install/native_linux/install-onnx.html
# Using torchaudio CPU for compatibility
# The extra index of PyTorch has no use here, just a fail-safe.
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install --break-system-packages \
    https://repo.radeon.com/rocm/manylinux/rocm-rel-6.2.3/torch-2.3.0%2Brocm6.2.3-cp310-cp310-linux_x86_64.whl \
    https://repo.radeon.com/rocm/manylinux/rocm-rel-6.2.3/torchvision-0.18.0%2Brocm6.2.3-cp310-cp310-linux_x86_64.whl \
    https://repo.radeon.com/rocm/manylinux/rocm-rel-6.2.3/pytorch_triton_rocm-2.3.0%2Brocm6.2.3.5a02332983-cp310-cp310-linux_x86_64.whl \
    https://repo.radeon.com/rocm/manylinux/rocm-rel-6.2.3/onnxruntime_rocm-1.18.0-cp310-cp310-linux_x86_64.whl \
    https://repo.radeon.com/rocm/manylinux/rocm-rel-6.2/jaxlib-0.4.23%2Brocm620-cp310-cp310-manylinux2014_x86_64.whl \
    https://repo.radeon.com/rocm/manylinux/rocm-rel-6.2/rocpydecode-1.0.0.0-py3-none-manylinux_2_28_x86_64.whl \
    https://download.pytorch.org/whl/cpu/torchaudio-2.3.0%2Bcpu-cp310-cp310-linux_x86_64.whl \
    --extra-index-url https://download.pytorch.org/whl/rocm6.2

# Dependencies for frequently-used
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install --break-system-packages \
    -r https://raw.githubusercontent.com/comfyanonymous/ComfyUI/master/requirements.txt \
    -r https://raw.githubusercontent.com/ltdrdata/ComfyUI-Manager/main/requirements.txt \
    -r https://raw.githubusercontent.com/cubiq/ComfyUI_essentials/main/requirements.txt \
    -r https://raw.githubusercontent.com/Fannovel16/comfyui_controlnet_aux/main/requirements.txt \
    -r https://raw.githubusercontent.com/jags111/efficiency-nodes-comfyui/main/requirements.txt \
    --extra-index-url https://download.pytorch.org/whl/rocm6.2

# Dependencies for more, with few hand-pick:
# 'compel lark' for smZNodes
# 'torchdiffeq' for DepthFM
# 'fairscale' for APISR
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install --break-system-packages \
    -r https://raw.githubusercontent.com/crystian/ComfyUI-Crystools/main/requirements.txt \
    -r https://raw.githubusercontent.com/cubiq/ComfyUI_FaceAnalysis/main/requirements.txt \
    -r https://raw.githubusercontent.com/cubiq/ComfyUI_InstantID/main/requirements.txt \
    -r https://raw.githubusercontent.com/Fannovel16/ComfyUI-Frame-Interpolation/main/requirements-no-cupy.txt \
    -r https://raw.githubusercontent.com/FizzleDorf/ComfyUI_FizzNodes/main/requirements.txt \
    -r https://raw.githubusercontent.com/kijai/ComfyUI-KJNodes/main/requirements.txt \
    -r https://raw.githubusercontent.com/ltdrdata/ComfyUI-Impact-Pack/Main/requirements.txt \
    -r https://raw.githubusercontent.com/ltdrdata/ComfyUI-Impact-Subpack/main/requirements.txt \
    -r https://raw.githubusercontent.com/ltdrdata/ComfyUI-Inspire-Pack/main/requirements.txt \
    -r https://raw.githubusercontent.com/melMass/comfy_mtb/main/requirements.txt \
    -r https://raw.githubusercontent.com/storyicon/comfyui_segment_anything/main/requirements.txt \
    -r https://raw.githubusercontent.com/ZHO-ZHO-ZHO/ComfyUI-InstantID/main/requirements.txt \
    compel lark torchdiffeq fairscale \
    python-ffmpeg \
    --extra-index-url https://download.pytorch.org/whl/rocm6.2

# Fix MediaPipe's broken dep (protobuf<4).
RUN --mount=type=cache,target=/root/.cache/pip \
    pip install --break-system-packages \
    mediapipe \
    && pip list

RUN df -h \
    && du -ah /root \
    && find /root/ -mindepth 1 -delete

COPY runner-scripts/.  /runner-scripts/

RUN groupadd -r video
USER root
VOLUME /root
WORKDIR /root
EXPOSE 8188
ENV CLI_ARGS=""
CMD ["bash","/runner-scripts/entrypoint.sh"]