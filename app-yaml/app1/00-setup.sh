#!/bin/bash

mkdir -p /mnt/data/nginx-apps1/
 
kubectl apply -f 01-nginx-apps1-pv.yaml -f 02-nginx-apps1-pvc.yaml -f 03-nginx-deployment-apps1.yaml 
