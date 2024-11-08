#!/bin/bash

# for Lets Encrypt use

helm repo add jetstack https://charts.jetstack.io --force-update

echo "Intalling cert-manager ..will take few min..."
helm install \
  cert-manager jetstack/cert-manager \
  --namespace cert-manager \
  --create-namespace \
  --version v1.16.1 \
  --set crds.enabled=true

echo "wait ..."
sleep 10
kubectl get pods --namespace cert-manager
