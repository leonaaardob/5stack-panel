#!/bin/bash

source setup-env.sh "$@"

if [ "$REVERSE_PROXY" = true ]; then
    ./kustomize build base | kubectl --kubeconfig=$KUBECONFIG apply -f -
else 
    kubectl --kubeconfig=$KUBECONFIG apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.16.1/cert-manager.yaml
    ./kustomize build overlays/cert-manager | kubectl --kubeconfig=$KUBECONFIG apply -f -
fi

kubectl --kubeconfig=$KUBECONFIG delete deployment minio -n 5stack
kubectl --kubeconfig=$KUBECONFIG delete deployment timescaledb -n 5stack
kubectl --kubeconfig=$KUBECONFIG delete deployment typesense -n 5stack

echo "5stack Updated"
