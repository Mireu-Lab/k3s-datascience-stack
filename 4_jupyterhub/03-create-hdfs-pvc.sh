#!/bin/bash
set -e

echo "================================================"
echo "Creating HDFS PVC for JupyterHub Mount"
echo "================================================"
echo ""

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: hdfs-pvc
  namespace: jupyterhub
spec:
  accessModes:
    - ReadWriteMany
  storageClassName: nfs-hdfs
  resources:
    requests:
      storage: 200Gi
---
apiVersion: v1
kind: PersistentVolume
metadata:
  name: hdfs-pv
spec:
  capacity:
    storage: 200Gi
  accessModes:
    - ReadWriteMany
  storageClassName: nfs-hdfs
  nfs:
    server: hdfs-namenode-0.hdfs-namenode.hdfs.svc.cluster.local
    path: /
  mountOptions:
    - nfsvers=4.1
    - hard
    - timeo=600
    - retrans=2
EOF

echo ""
echo "================================================"
echo "HDFS PVC Created Successfully"
echo "================================================"
echo ""
echo "Note: This assumes HDFS is exposing NFS service."
echo "If using HDFS directly, modify the mount strategy in values.yaml"
echo ""
