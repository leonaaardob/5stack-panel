#!/bin/bash

source setup-env.sh "$@"

namespace="5stack"


echo "Checking pod status and restarts in namespace $namespace..."
echo "---------------------------------------"

# Get all pods in the namespace
kubectl --kubeconfig=$KUBECONFIG get pods -n "$namespace" --no-headers | while read -r pod; do
    pod_name=$(echo "$pod" | awk '{print $1}')
    restarts=$(echo "$pod" | awk '{print $4}')
    
    echo "Pod: $pod_name"
    echo "Total restarts: $restarts"
    
    if [ "$restarts" -gt 0 ]; then
        echo "Last restart reason:"
        kubectl --kubeconfig=$KUBECONFIG get pod "$pod_name" -n "$namespace" -o jsonpath='{.status.containerStatuses[0].lastState.terminated.reason}'
        echo -e "\n"
        
        kubectl --kubeconfig=$KUBECONFIG logs "$pod_name" -n "$namespace" --tail=100
    fi
    
    echo "---------------------------------------"
done

echo "Checking certificates in namespace $namespace..."
echo "---------------------------------------"

# Loop through all certificates in all namespaces
for cert in $(kubectl --kubeconfig=$KUBECONFIG get certificates -A -o custom-columns=NAME:.metadata.name --no-headers | awk '{print $1}'); do
  name=$(echo "$cert" | cut -d'/' -f2)

  # Get the Ready condition status for the certificate
  status=$(kubectl --kubeconfig=$KUBECONFIG get certificate "$name" -n "$namespace" -o jsonpath='{.status.conditions[?(@.type=="Ready")].status}')

  # If the certificate is valid, skip to the next
  if [[ "$status" == "True" ]]; then
    echo "Certificate $name in namespace $namespace is valid."
  else
    echo "Certificate $name in namespace $namespace is not valid. Fetching details..."

    # Get details of the certificate
    kubectl --kubeconfig=$KUBECONFIG describe certificate "$name" -n "$namespace"

    # Find associated challenges for this certificate
    echo "Checking challenges for certificate $name..."

    # Get all challenges in the same namespace and filter by the certificate name
    kubectl --kubeconfig=$KUBECONFIG get challenges -n "$namespace" --no-headers | grep "$name" | while read -r challenge; do
      challenge_name=$(echo "$challenge" | awk '{print $1}')

      # Check if the challenge is valid
      challenge_status=$(kubectl --kubeconfig=$KUBECONFIG get challenge "$challenge_name" -n "$namespace" -o jsonpath='{.status.state}')

      # Only fetch details if the challenge is not valid
      if [[ "$challenge_status" != "valid" ]]; then
        echo "Challenge $challenge_name for certificate $name is not valid. Fetching details..."
        kubectl --kubeconfig=$KUBECONFIGdescribe challenge "$challenge_name" -n "$namespace"
      else
        echo "Challenge $challenge_name for certificate $name is valid."
      fi
    done
  fi

  echo "---------------------------------------"
done