#!/bin/bash

# ==============================================================================
# Master Deployment Script for K3s Data Science Stack
# ==============================================================================
# This script guides you through the entire deployment process, including
# manual prerequisites and automated deployment of the Kubernetes stack.
#
# Please execute this script from the root of the project directory.
# ==============================================================================

set -e # Exit immediately if a command exits with a non-zero status.

# Function to print colored headings
print_header() {
    echo ""
    echo "=============================================================================="
    echo " $1"
    echo "=============================================================================="
}

# --- Step 0: Manual Prerequisites ---
print_header "Step 0: Manual Prerequisites"
echo "Before running the automated deployment, please ensure you have completed the following:"
echo "1. Disk Partitioning and Mounting:"
echo "   - NVMe SSD (2TB) is mounted at /mnt/nvme"
echo "   - HDD (2TB) is mounted at /mnt/hdd"
echo "   (These paths are configured in deployments/storage/storage-pv.yaml)"
echo ""
echo "2. Google OAuth Credentials for JupyterHub:"
echo "   - Create OAuth 2.0 Client ID in Google Cloud Console."
echo "   - Note down your Client ID and Client Secret."
echo "   - You will need to update these in 'deployments/jupyterhub/deploy.sh'."
echo ""
echo "3. GCP Service Account for Data Archiving:"
echo "   - Create a GCP Service Account with 'Storage Object Admin' role."
echo "   - Download the JSON key file."
echo "   - Follow the instructions in 'deployments/hadoop/setup-gcp-credentials.sh.template' to create the Kubernetes secret."
echo ""
read -p "Have you completed all the manual prerequisites? (y/n) " -n 1 -r
echo ""
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo "Aborting deployment. Please complete the prerequisites."
    exit 1
fi

# --- Step 1: Automated Deployment ---
print_header "Step 1: Starting Automated Deployment"
echo "This will deploy the entire stack using the scripts in the 'deployments' directory."
read -p "Press [Enter] to begin the automated deployment..."

# Execute the deploy-all script
if [ -f "deployments/deploy-all.sh" ]; then
    bash "deployments/deploy-all.sh"
else
    echo "Error: 'deployments/deploy-all.sh' not found."
    exit 1
fi

print_header "Deployment Summary"
echo "The deployment script has finished."
echo "Here are the URLs for the services:"
echo " - JupyterHub:  https://jupyter.mireu.xyz"
echo " - Grafana:     https://grafana.mireu.xyz"
echo ""
echo "It might take several minutes for all services to be fully operational and for"
echo "DNS to propagate. Use 'kubectl get pods --all-namespaces' to check the status."
echo "Enjoy your data science platform!"
