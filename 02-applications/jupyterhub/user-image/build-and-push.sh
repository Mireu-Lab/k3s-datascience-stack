#!/bin/bash
IMAGE_NAME="your-dockerhub-username/jupyter-data-server"
TAG="latest"

docker build -t ${IMAGE_NAME}:${TAG} .
docker push ${IMAGE_NAME}:${TAG}