echo "네임스페이스 및 스토리지 설정 중..."
kubectl apply -f 00-namespaces.yaml
kubectl apply -f 01-storage-pv.yaml
sleep 5