#!/bin/bash

# This script will patch the servers config map, install the app cert and restart the server components
# It is best to add the envs to your environment variables using `gp env GH_APP_ID=....` and `gp env GH_APP_KEY="..."`.

# GH_APP_ID=<app-id>
# GH_APP_KEY="-----BEGIN RSA PRIVATE KEY-----
# ...
# -----END RSA PRIVATE KEY-----"
#############################

if [ -z "$GH_APP_ID" ]; then
  echo "Missing env GH_APP_ID"
  return
fi

if [ -z "${GH_APP_KEY}" ]; then
  echo "Missing env GH_APP_KEY"
  return
fi

# patch the configmap
LINE="\"githubApp\": \{\"appId\":${GH_APP_ID},\"authProviderId\":\"Public-GitHub\",\"certPath\":\"/github-app-cert/cert\",\"certSecretName\":\"server-github-app-cert\",\"enabled\":true,\"marketplaceName\":\"gitpod-io\",\"webhookSecret\":\"omgsecret\"},"

kubectl get cm server-config -o yaml | \
  sed -E "s|\"githubApp\":.+},|${LINE}|" | \
  kubectl apply -f -

# update the secret
kubectl delete secret server-github-app-cert
kubectl create secret generic server-github-app-cert --from-literal=cert="$GH_APP_KEY"

# restart servers
kubectl rollout restart deployment server