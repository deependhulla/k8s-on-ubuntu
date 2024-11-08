#!/bin/bash

mkdir -p /mnt/data/nginx-apps2/

kubectl apply -f 01-nginx-apps2-pv.yaml -f 02-nginx-apps2-pvc.yaml -f 03-nginx-deployment-apps2.yaml 
