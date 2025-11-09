# Base image with CUDA and Python
FROM nvidia/cuda:12.1.1-cudnn8-devel-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install Python, Spark dependencies, and other tools
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3.10 python3-pip openjdk-11-jre-headless git \
    && rm -rf /var/lib/apt/lists/*

# Install Python libraries
RUN pip3 install --no-cache-dir \
    jupyterlab \
    jupyterhub \
    oauthenticator \
    pyspark==3.5.0 \
    'jax[cuda12_pip]' -f https://storage.googleapis.com/jax-releases/jax_cuda_releases.html \
    pandas scikit-learn numpy

# Create a non-root user 'jovyan'
RUN useradd -ms /bin/bash jovyan
USER jovyan
WORKDIR /home/jovyan

# Expose JupyterLab port
EXPOSE 8888