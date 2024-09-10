#!/bin/bash

for file in base/secrets/*.env.example; do
    env_file="${file%.example}"
    if [ ! -f "$env_file" ]; then
        cp "$file" "$env_file"
    fi
done

for file in overlays/dev/secrets/*.env.example; do
    env_file="${file%.example}"
    if [ ! -f "$env_file" ]; then
        cp "$file" "$env_file"
    fi
done


for file in base/properties/*.env.example; do
    env_file="${file%.example}"
    if [ ! -f "$env_file" ]; then
        cp "$file" "$env_file"
    fi
done


# Replace $(RAND32) with a random base64 encoded string in all non-example env files
for env_file in base/secrets/*.env; do
    if [[ -f "$env_file" && ! "$env_file" == *.example ]]; then
        # Generate a random base64 encoded string
        random_string=$(openssl rand -base64 32)
        
        sed -i '' "s|\$(RAND32)|$random_string|g" "$env_file"
    fi
done

while [[ $# -gt 0 ]]; do
    case $1 in
        --kubeconfig)
            KUBECONFIG="$2"
            shift 2
            ;;
        *)
            echo "Unknown option: $1"
            exit 1
            ;;
    esac
done

if [ -z "$KUBECONFIG" ]; then
    KUBECONFIG="/etc/rancher/k3s/k3s.yaml"
fi


if ! [ -f ./kustomize ] || ! [ -x ./kustomize ]
then
    echo "kustomize not found. Installing..."
    curl -s "https://raw.githubusercontent.com/kubernetes-sigs/kustomize/master/hack/install_kustomize.sh" | bash
else
    echo "kustomize is already installed."
fi

echo "using kubeconfig: $KUBECONFIG"


POSTGRES_PASSWORD=$(grep "^POSTGRES_PASSWORD=" base/secrets/postgres-secrets.env | cut -d '=' -f2-)
POSTGRES_CONNECTION_STRING="postgres://hasura:$POSTGRES_PASSWORD@postgres:5432/hasura"

if grep -q "^POSTGRES_CONNECTION_STRING=" base/secrets/postgres-secrets.env; then
    # If it exists, update it
    sed -i '' "s|^POSTGRES_CONNECTION_STRING=.*|POSTGRES_CONNECTION_STRING=$POSTGRES_CONNECTION_STRING|" base/secrets/postgres-secrets.env
else
    echo "" >> base/secrets/postgres-secrets.env
    echo "POSTGRES_CONNECTION_STRING=$POSTGRES_CONNECTION_STRING" >> base/secrets/postgres-secrets.env
fi


./kustomize build base | kubectl --kubeconfig=$KUBECONFIG apply -f -

echo "5stack Updated"