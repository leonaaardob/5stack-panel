#!/bin/bash

KUBECONFIG=""
CUSTOM_DIR=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --kubeconfig)
            KUBECONFIG="$2"
            shift 2
            ;;
        *)
            CUSTOM_DIR="$1"
            shift
            ;;
    esac
done

if [ -z "$CUSTOM_DIR" ]; then
    echo "Error: CUSTOM_DIR is required."
    exit 1
fi

if [ -z "$KUBECONFIG" ]; then
    KUBECONFIG="/etc/rancher/k3s/k3s.yaml"
fi

./kustomize build ./custom/$CUSTOM_DIR | kubectl --kubeconfig=$KUBECONFIG apply -f -