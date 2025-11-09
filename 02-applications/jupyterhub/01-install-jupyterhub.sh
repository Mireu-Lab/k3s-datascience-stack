#!/bin/bash
helm repo add jupyterhub https://jupyterhub.github.io/helm-chart/
helm repo update
helm upgrade --cleanup-on-fail \
  --install jupyterhub jupyterhub/jupyterhub \
  --namespace jupyterhub \
  --version=3.2.0 \
  --values 03-jupyterhub-values.yaml