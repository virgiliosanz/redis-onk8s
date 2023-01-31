# Redis Enterprise on Kubernetes

A repository with scripts and yaml to deploy & use Redis on Kubernetes with Redis Labs Redis Enteprise Kubernetes CRD and operator.

TODO
- clean up this readme (for now ignore what's below)
- link subfolder readme
- screenshot from OpenShift 3.11 setup
- note about dense & sparce placement
- terraforming OpenShift 3.11






# Installation

```
curl --silent https://api.github.com/repos/RedisLabs/redis-enterprise-k8s-docs/releases/latest | grep tag_name | awk -F'"' '{print $4}'

curl --silent -O https://raw.githubusercontent.com/RedisLabs/redis-enterprise-k8s-docs/v6.0.20-4/bundle.yaml

kubectl apply -f bundle.yaml
kubectl get deployment
kubectl get crd


```
# Usage

kubectl apply -f simple-cluster.yaml
kubectl rollout status sts/test-cluster
(few mins)

kubectl get all
kubectl get rec
kubectl describe  service/test-cluster-ui

kubectl get secrets test-cluster -o json | jq .data
kubectl port-forward service/test-cluster-ui 8443:8443
    kubectl expose service/test-cluster-ui --type=NodePort --name=ui
    kubectl describe service/ui
        ... NodePort:                 <unset>  31104/TCP

kubectl get secret test-cluster -o jsonpath="{.data.password}" | base64 --decode
https://localhost:31104

kubectl apply -f small-db.yml
kubectl get redb
kubectl get redb/smalldb -o json | jq .status.internalEndpoints
kubectl get secret redb-smalldb -o json | jq .data.password -r | base64 --decode

kubectl port-forward service/smalldb 17893:17893


# Kuberntes

kubectl get nodes
kubectl config get-contexts
kubectl get storageclasses
kubectl get namespaces
kubectl get all




# Links

# K8s UI for Docker K8s

https://andrewlock.net/running-kubernetes-and-the-dashboard-with-docker-desktop/
