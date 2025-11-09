.
mkdir 00-initial-setup
touch 00-initial-setup/01-setup-disks.sh
touch 00-initial-setup/02-install-prereqs.sh

mkdir 01-k3s-core
touch 01-k3s-core/01-storage-class.yaml
touch 01-k3s-core/02-cloudflare-secrets.yaml

mkdir 02-applications
mkdir 02-applications/cert-manager
touch 02-applications/cert-manager/01-install-cert-manager.sh
touch 02-applications/cert-manager/02-cluster-issuer.yaml

mkdir 02-applications/cloudflare-tunnel
touch 02-applications/cloudflare-tunnel/01-install-cloudflared.sh
touch 02-applications/cloudflare-tunnel/02-cloudflared-config.yaml

mkdir 02-applications/hadoop-hdfs
touch 02-applications/hadoop-hdfs/01-hdfs-configmap.yaml
touch 02-applications/hadoop-hdfs/02-namenode-statefulset.yaml
touch 02-applications/hadoop-hdfs/03-datanode-daemonset.yaml

mkdir 02-applications/jupyterhub
mkdir 02-applications/jupyterhub/user-image
touch 02-applications/jupyterhub/user-image/Dockerfile
touch 02-applications/jupyterhub/user-image/build-and-push.sh
touch 02-applications/jupyterhub/01-namespace.yaml
touch 02-applications/jupyterhub/02-jupyterhub-pvc.yaml
touch 02-applications/jupyterhub/03-jupyterhub-values.yaml

mkdir 02-applications/postgresql
touch 02-applications/postgresql/01-postgresql-helm-values.yaml

mkdir 03-automation
touch 03-automation/01-data-mover-cronjob.yaml
