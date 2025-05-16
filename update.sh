#!/bin/bash

source setup-env.sh "$@"

if [ "$REVERSE_PROXY" = true ]; then
    ./kustomize build base | output_redirect kubectl --kubeconfig=$KUBECONFIG apply -f -
    kubectl --kubeconfig=$KUBECONFIG delete certificate 5stack-ssl -n 5stack 2>/dev/null
else 
    ./kustomize build overlays/cert-manager | output_redirect kubectl --kubeconfig=$KUBECONFIG apply -f -
fi

kubectl --kubeconfig=$KUBECONFIG delete deployment minio -n 5stack 2>/dev/null
kubectl --kubeconfig=$KUBECONFIG delete deployment timescaledb -n 5stack  2>/dev/null
kubectl --kubeconfig=$KUBECONFIG delete deployment typesense -n 5stack  2>/dev/null

GIT_SHA=$(git rev-parse --short HEAD)

kubectl --kubeconfig=$KUBECONFIG label node $(kubectl --kubeconfig=$KUBECONFIG get nodes --selector='node-role.kubernetes.io/control-plane') 5stack-panel-version=$GIT_SHA --overwrite

echo "5Stack : Updated"
