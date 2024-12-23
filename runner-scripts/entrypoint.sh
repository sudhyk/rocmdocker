#!/bin/bash

set -e


# Install ComfyUI
cd /root
if [ ! -f "/root/.download-complete" ] ; then
    chmod +x /runner-scripts/download.sh
    bash /runner-scripts/download.sh
fi ;


echo "########################################"
echo "[INFO] Starting ComfyUI..."
echo "########################################"

# Let .pyc files be stored in one place
export PYTHONPYCACHEPREFIX="/root/.cache/pycache"
# Let PIP install packages to /root/.local
export PIP_USER=true
# Add above to PATH
export PATH="${PATH}:/root/.local/bin"
# Suppress [WARNING: Running pip as the 'root' user]
export PIP_ROOT_USER_ACTION=ignore

cd /root

chmod -R 777 ./ComfyUI/custom_nodes
chmod -R 777 ./ComfyUI/models

python3 ./ComfyUI/main.py --listen --port 8188 ${CLI_ARGS}
