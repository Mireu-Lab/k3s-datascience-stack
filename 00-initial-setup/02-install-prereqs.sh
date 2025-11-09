#!/bin/bash

# --- 1. Uninstall old versions (if they exist) ---
echo "--- Removing old installations (if any) ---"
/usr/local/bin/k3s-uninstall.sh || echo "K3s not found, skipping uninstall."
sudo apt-get purge -y "nvidia-*"
sudo apt-get purge -y "containerd"
sudo rm -f /usr/local/bin/helm /usr/local/bin/kubectl

# --- 2. Install NVIDIA Drivers ---
if ! command -v nvidia-smi &> /dev/null; then
    echo "--- Installing NVIDIA Drivers ---"
    sudo apt-get update
    sudo apt-get install -y ubuntu-drivers-common
    sudo ubuntu-drivers autoinstall
    echo "NVIDIA drivers installed. A REBOOT IS RECOMMENDED."
else
    echo "NVIDIA drivers already installed."
    nvidia-smi
fi

# --- 3. Install Prerequisite Tools (curl, git) ---
sudo apt-get update
sudo apt-get install -y curl git

# --- 4. Install K3s with containerd ---
if ! command -v k3s &> /dev/null; then
    echo "--- Installing K3s ---"
    curl -sfL https://get.k3s.io | INSTALL_K3S_EXEC="--docker=false --disable=traefik" sh -
    # Wait for K3s to be ready
    sleep 30
    sudo chmod 644 /etc/rancher/k3s/k3s.yaml
else
    echo "K3s is already installed."
fi

# --- 5. Install kubectl ---
if ! command -v kubectl &> /dev/null; then
    echo "--- Installing kubectl ---"
    curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl
    mkdir -p $HOME/.kube
    sudo cp /etc/rancher/k3s/k3s.yaml $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config
else
    echo "kubectl is already installed."
fi

# --- 6. Install Helm ---
if ! command -v helm &> /dev/null; then
    echo "--- Installing Helm ---"
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
else
    echo "Helm is already installed."
fi

echo "--- Prerequisite installation complete! ---"
echo "Please set up your KUBECONFIG:"
echo "export KUBECONFIG=~/.kube/config"