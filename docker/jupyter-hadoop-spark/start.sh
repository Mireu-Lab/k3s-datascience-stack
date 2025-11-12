#!/bin/bash

# Startup script for Jupyter container

set -e

# Default values
USER_EMAIL=${JUPYTERHUB_USER:-jovyan}

# Sanitize email for use as a directory name
SAFE_EMAIL=$(echo "$USER_EMAIL" | tr '@.' '_')

# Define the workspace directory
WORK_DIR="/home/jovyan/$SAFE_EMAIL"

# Create the directory if it doesn't exist
mkdir -p "$WORK_DIR"

# Copy the package list to the workspace
cp /opt/packages.txt "$WORK_DIR/packages.txt"

# Start JupyterLab in the user's workspace
exec jupyter-lab \
    --allow-root \
    --ip=0.0.0.0 \
    --port=8888 \
    --no-browser \
    --notebook-dir="$WORK_DIR" \
    --NotebookApp.token='' \
    --NotebookApp.password='' \
    --NotebookApp.base_url=${JUPYTERHUB_SERVICE_PREFIX} \
    --NotebookApp.default_url=/lab