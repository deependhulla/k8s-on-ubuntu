#!/bin/bash

# CD to a temporary directory
cd /tmp

# Install K3s Kubernetes with specific options (no cloud controller and all prefer bundle package in bin)
curl -sfL https://get.k3s.io | sh -s - --prefer-bundled-bin --disable-cloud-controller

echo "Please wait while the pods are being created. This process downloads around 1.5GB of data and sets up the environment."
sleep 30

# Check initial status of pods
kubectl get pods -A

# Wait for pods to finish setting up, checking every 30 seconds
echo "Pods are being created. Checking status in intervals..."
for i in {1..4}; do
  sleep 30
  kubectl get pods -A
done

# Show the status of services as well
kubectl get services

# Provide instructions for further checks
echo "To recheck the status at any time, use: kubectl get pods -A"

# Return to the previous directory
cd -

