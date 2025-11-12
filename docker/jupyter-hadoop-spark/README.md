# Jupyter Hadoop + Spark + JAX Image

This image adds Hadoop client (hdfs, hadoop-fuse-dfs), PySpark, and JAX to a CUDA-enabled Jupyter base.

## Build

```bash
cd docker/jupyter-hadoop-spark
# Replace image name as needed
docker build -t ghcr.io/mireu-lab/jupyter-hadoop-spark:latest .
```

## Push

```bash
docker push ghcr.io/mireu-lab/jupyter-hadoop-spark:latest
```

## Use in JupyterHub

Set in `deployments/jupyterhub/values.yaml`:

```yaml
singleuser:
  image:
    name: ghcr.io/mireu-lab/jupyter-hadoop-spark
    tag: latest
```

The container expects these env vars (already set in values.yaml):
- HDFS_NAMENODE (default: hdfs://hdfs-cluster-namenode:8020)
- SPARK_K8S_MASTER (default: k8s://https://kubernetes.default.svc)
- SPARK_DRIVER_SERVICE_ACCOUNT (default: jhub-user-sa)
