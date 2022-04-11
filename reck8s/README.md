# USAGE

```
kubectl get secret  rec -o jsonpath='{.data.password}' -n redis  | base64 --decode
YWRtaW5STDEyMw==

kubectl port-forward service/rec-ui 8443:8443 -n redis

kubectl logs pod/redis-enterprise-operator-7b57659db5-jx9rv redis-enterprise-operator

kubectl run redis-cli --image redis:latest --attach --leave-stdin-open --rm -it --command -- bash
```

# MULTI NAMESPACE

From the project namespace, enable roles for operator access
and for the `redis` namespace, ensure project is monitored for `redb`

Example setup
```
kubectl create namespace proja
kubens proja
./rec_access.sh
kubectl apply -f <...redb.yaml>
```

Example to access a database
```
kubectl get redb

kubectl get secret redb-db -o jsonpath='{.data.password}' | base64 --decode

kubectl run redis-cli --image redis:latest --attach --leave-stdin-open --rm -it --command -- bash

redis-cli -h redis-18627.redis.svc.cluster.local -p 18627
```


# (BETA/NOT STABLE) PROMETHEUS & GRAFANA

https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack

see also
https://github.com/prometheus-community/helm-charts/blob/main/charts/kube-prometheus-stack/values.yaml

```
//cd monitoring
kubectl create namespace monitoring
kubectl label namespace monitoring redis-prometheus=enable
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
helm install monitoring prometheus-community/kube-prometheus-stack --values values.yaml
```


kubectl port-forward service/monitoring-grafana 8080:80 -n monitoring
kubectl get secrets monitoring-grafana -o json
admin / prom-operator
http://localhost:8080




```
//cd ..
kubens redis
kubectl label namespace redis redis-prometheus=enable
kubectl apply -f prometheus-rec.yaml
```

# HACK

kubectl port-forward service/rec-prom 8070:8070

https://localhost:8070
http://localhost:9090
http://localhost:3000
