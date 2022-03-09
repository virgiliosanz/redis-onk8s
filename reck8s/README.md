# USAGE

kubectl get secret  rec -o jsonpath='{.data.password}' -n redis  | base64 --decode

kubectl port-forward service/rec-ui 8443:8443 -n redis

kubectl logs pod/redis-enterprise-operator-7b57659db5-jx9rv redis-enterprise-operator

kubectl run redis-cli --image redis:latest --attach --leave-stdin-open --rm -it --command -- bash

# PROMETHEUS & GRAFANA

https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack
see also
https://github.com/prometheus-community/helm-charts/blob/main/charts/kube-prometheus-stack/values.yaml

//cd monitoring
kubectl create namespace monitoring
kubectl label namespace monitoring redis-prometheus=enable
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install monitoring prometheus-community/kube-prometheus-stack --values values.yaml

//cd ..
kubens redis
kubectl label namespace redis redis-prometheus=enable
kubectl apply -f prometheus-rec.yaml

