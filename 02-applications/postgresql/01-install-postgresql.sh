#!/bin/bash
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
helm install postgresql bitnami/postgresql \
    --namespace database \
    --create-namespace \
    -f 01-postgresql-helm-values.yaml