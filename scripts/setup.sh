#!/bin/bash
# K3s Data Science Stack 초기 설정 스크립트

set -e

echo "=========================================="
echo "K3s Data Science Stack - Initial Setup"
echo "=========================================="

# 색상 정의
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 함수 정의
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

check_command() {
    if ! command -v $1 &> /dev/null; then
        print_error "$1 could not be found"
        return 1
    fi
    print_info "$1 is installed"
    return 0
}

# 1. 시스템 요구사항 확인
print_info "Checking system requirements..."

if ! check_command kubectl; then
    print_error "kubectl is required. Please install it first."
    exit 1
fi

if ! check_command helm; then
    print_error "helm is required. Please install it first."
    exit 1
fi

# 2. 디스크 마운트 확인
print_info "Checking disk mounts..."

if ! mountpoint -q /mnt/nvme; then
    print_warn "/mnt/nvme is not mounted"
    read -p "Do you want to continue? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
else
    print_info "/mnt/nvme is mounted"
fi

if ! mountpoint -q /mnt/hdd; then
    print_warn "/mnt/hdd is not mounted"
    read -p "Do you want to continue? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
else
    print_info "/mnt/hdd is mounted"
fi

# 3. 디렉토리 생성
print_info "Creating directories..."

sudo mkdir -p /mnt/nvme/hot-data
sudo mkdir -p /mnt/hdd/cold-data

sudo chmod 777 /mnt/nvme/hot-data
sudo chmod 777 /mnt/hdd/cold-data

print_info "Directories created and permissions set"

# 4. Helm Repositories 추가
print_info "Adding Helm repositories..."

helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo add jupyterhub https://hub.jupyter.org/helm-chart/
helm repo add jetstack https://charts.jetstack.io

helm repo update

print_info "Helm repositories added and updated"

# 5. Namespaces 생성
print_info "Creating Kubernetes namespaces..."

kubectl apply -f k8s/00-namespaces/namespace.yaml

print_info "Namespaces created"

# 6. Storage 설정
print_info "Configuring storage..."

kubectl apply -f k8s/01-storage/storage-class.yaml

print_info "Storage configured"

# 7. cert-manager 설치
print_info "Installing cert-manager..."

kubectl create namespace cert-manager --dry-run=client -o yaml | kubectl apply -f -

kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.13.3/cert-manager.crds.yaml

helm upgrade --install cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --version v1.13.3 \
  --set installCRDs=false \
  --wait

print_info "cert-manager installed"

# 8. NVIDIA Device Plugin 확인
print_info "Checking NVIDIA Device Plugin..."

if kubectl get daemonset -n kube-system | grep -q nvidia-device-plugin; then
    print_info "NVIDIA Device Plugin is already installed"
else
    print_warn "NVIDIA Device Plugin is not installed"
    print_info "Installing NVIDIA Device Plugin..."
    kubectl create -f https://raw.githubusercontent.com/NVIDIA/k8s-device-plugin/v0.14.3/nvidia-device-plugin.yml
fi

# 9. 설정 확인
print_info "Verifying installation..."

echo ""
echo "=========================================="
echo "Installation Status:"
echo "=========================================="
echo ""

kubectl get nodes
echo ""

kubectl get namespaces
echo ""

kubectl get storageclass
echo ""

kubectl get pv
echo ""

kubectl get pvc -A
echo ""

kubectl get pods -n cert-manager
echo ""

echo ""
echo "=========================================="
echo "Next Steps:"
echo "=========================================="
echo ""
echo "1. Update configuration files with your actual values:"
echo "   - k8s/02-postgresql/values.yaml"
echo "   - k8s/03-hadoop/values.yaml"
echo "   - k8s/04-spark/values.yaml"
echo "   - k8s/05-jupyterhub/values.yaml"
echo "   - k8s/05-jupyterhub/secrets.yaml"
echo "   - k8s/06-data-backup/cronjobs.yaml"
echo "   - k8s/07-ingress/ingress.yaml"
echo ""
echo "2. Build and push Docker image:"
echo "   cd docker/jupyter-jax-gpu"
echo "   docker build -t your-registry/jupyter-jax-gpu:latest ."
echo "   docker push your-registry/jupyter-jax-gpu:latest"
echo ""
echo "3. Deploy services:"
echo "   ./scripts/deploy.sh"
echo ""
echo "=========================================="
echo "Setup completed successfully!"
echo "=========================================="
