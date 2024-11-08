#!/bin/bash



read -p "Please provide your email for Let's Encrypt: " leemail


   
    # Exit if no email is provided
    if [ -z "$leemail" ]; then
        echo "No email address provided. Exiting..."
        exit 1
    fi

echo  "Got Email as $leemail " 

/bin/cp app-yaml/cluster-issuer-production.yaml /tmp/
/bin/cp app-yaml/cluster-issuer-staging.yaml /tmp/


sed -i "s/your@emaildomain.com/$leemail/" /tmp/cluster-issuer-production.yaml
sed -i "s/your@emaildomain.com/$leemail/" /tmp/cluster-issuer-staging.yaml

## update your email address first in these files
kubectl apply -f /tmp/cluster-issuer-staging.yaml 
kubectl apply -f /tmp/cluster-issuer-production.yaml

echo "Waiting for registeration ..wait few min ..to get it True"
sleep 20
kubectl get ClusterIssuer -A

#kubectl describe clusterissuer letsencrypt-staging
#kubectl describe clusterissuer letsencrypt-production
