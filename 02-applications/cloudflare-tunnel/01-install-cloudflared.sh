#!/bin/bash
helm repo add cloudflare https://cloudflare.github.io/helm-charts
helm repo update
helm install cloudflared cloudflare/cloudflare-tunnel \
    --namespace cloudflare \
    --create-namespace \
    -f 02-cloudflared-config.yaml