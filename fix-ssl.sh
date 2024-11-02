#!/bin/bash

source setup-env.sh "$@"

kubectl --kubeconfig=$KUBECONFIG  delete ingresses --all -n 5stack

source update.sh "$@"
