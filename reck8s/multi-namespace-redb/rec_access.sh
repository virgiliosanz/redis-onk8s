#!/bin/bash

kubectl apply -f role.yaml
kubectl apply -f role_binding.yaml

kubectl patch configmap/operator-environment-config \
  -n redis \
  --type merge \
  -p '{"data":{"REDB_NAMESPACES":"proja"}}'
# comma separated list of namespace to enable access for
