#!/bin/bash
set -e

echo "================================================"
echo "Building Custom JupyterHub Docker Image"
echo "================================================"
echo ""
echo "NOTE: This image is built and deployed via GitHub Actions"
echo "      See: .github/workflows/build-jupyterhub-image.yml"
echo ""
echo "To trigger a build:"
echo "  1. Push Dockerfile changes to main branch"
echo "  2. Or manually trigger workflow from GitHub Actions tab"
echo ""
echo "Image will be available at:"
echo "  ghcr.io/mireu-lab/jupyterhub-cuda-jax:latest"
echo ""
echo "================================================"
echo "Local Build (for testing only)"
echo "================================================"
echo ""

# Configuration
IMAGE_NAME="jupyterhub-cuda-jax"
IMAGE_TAG="local-test"
REGISTRY="${DOCKER_REGISTRY:-ghcr.io/mireu-lab}"
FULL_IMAGE_NAME="${REGISTRY}/${IMAGE_NAME}:${IMAGE_TAG}"

echo "Image: ${FULL_IMAGE_NAME}"
echo ""

read -p "Do you want to build locally for testing? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Build cancelled. Use GitHub Actions for production builds."
    exit 0
fi

# Build Docker image
echo "[1/2] Building Docker image locally..."
docker build -t ${FULL_IMAGE_NAME} -f 4_jupyterhub/Dockerfile .

echo ""
echo "Local build complete: ${FULL_IMAGE_NAME}"
echo ""
echo "To test locally, update values.yaml temporarily:"
echo ""
echo "singleuser:"
echo "  image:"
echo "    name: ${REGISTRY}/${IMAGE_NAME}"
echo "    tag: ${IMAGE_TAG}"
echo "    pullPolicy: IfNotPresent"
echo ""
echo "For production deployment, use GitHub Actions built image:"
echo "  ghcr.io/mireu-lab/jupyterhub-cuda-jax:latest"
echo ""
