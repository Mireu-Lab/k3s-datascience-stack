#!/bin/bash

# Startup script for Jupyter container
# Clone Git repo if specified

set -e

REPO_URL=${GIT_REPO_URL:-https://github.com/Mireu-Lab/k3s-datascience-stack}
REPO_NAME=${GIT_REPO_NAME:-default-repo}
WORK_DIR="/home/jovyan/$REPO_NAME"

if [ ! -d "$WORK_DIR" ]; then
    echo "Cloning repository $REPO_URL to $WORK_DIR"
    git clone "$REPO_URL" "$WORK_DIR"
else
    echo "Repository already exists at $WORK_DIR"
fi

# Start JupyterLab
exec jupyter-lab --allow-root --ip=0.0.0.0 --port=8888 --no-browser --NotebookApp.token= --NotebookApp.password= --NotebookApp.base_url=${JUPYTERHUB_SERVICE_PREFIX} --NotebookApp.default_url=/lab