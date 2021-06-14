# Redis Enterprise on OpenShift and multicloud Active/Active with Redis Enterprise on Google GCP

Notes for OpenShift setup, RS K8s operator, and CRDB setup.

The RS on GCP being used is from my other repository.

Assume that `$PASSWORD` is your secret password.

# OpenShift Infrastructure setup

You need
- CentOS 7 (does not work with CentOS 8 due to python and Ansible)
- 32GB RAM
- 100GB storage
- eu-west-1

Access with
`gcloud compute ssh avasseur-okd-7`

# OpenShift OKD - CentOS 7 (single VM demo)

Skip this part if you already have OpenShift 3.11

## Installation

See scripts from 
https://github.com/Redislabs-Solution-Architects/RedisEntrpr-Openshift-Community-Distribution
(but don't do the RS part - follow the product documentation and new repository instead - next section)

Make sure to ssh into with new key to avoid key alert at install time

```
yum -y update
yum install -y git tmux wget

wget https://github.com/openshift/origin/releases/download/v3.11.0/openshift-origin-client-tools-v3.11.0-0cbc58b-linux-64bit.tar.gz
tar xvf openshift-origin-client-tools*.tar.gz
cd openshift-origin-client*/
sudo mv  oc kubectl  /usr/local/bin/

export DOMAIN=avasseur-okd.demo.redislabs.com
export USERNAME=admin
export PASSWORD=$PASSWORD
```

Configure DNS with
```
A       avasseur-okd.demo.redislabs.com     35.189.231.170
CNAME   *.avasseur-okd.demo.redislabs.com   avasseur-okd.demo.redislabs.com
```

Access
- https://console.avasseur-okd.demo.redislabs.com:8443/
- https://console.apps.avasseur-okd.demo.redislabs.com/k8s/cluster/nodes
with your admin/$PASSWORD account.

You can also download Mac client
https://github.com/openshift/origin/releases/tag/v3.11.0

Change admin password
```
htpasswd -b /etc/origin/master/htpasswd admin $PASSWORD
```


## Deploying Redis open source in OpenShift

Example usage
```
oc login -u admin -p $PASSWORD https://console.avasseur-okd.demo.redislabs.com:8443/
oc status
kubectl get all
```

Optional - setup local redis-cli to test access from VM node itself with clusterIP
```
wget http://download.redis.io/redis-stable.tar.gz
tar xvzf redis-stable.tar.gz
cd redis-stable
make redis-cli
sudo cp src/redis-cli /usr/local/bin/
```

Recommanded - just run a Redis container to have redis-cli
```
oc new-project alex-project
oc new-app docker.io/redis:latest
```

Example - Exposing a Redis service on a NodePort public IP and port
```
oc get svc
redis-cli -h <clusterIP>
oc expose service/redis --type=NodePort --generator=service/v2 --name=redisnp
oc get svc
redis-cli -h svc.avasseur-okd.demo.redislabs.com -p 32364
```

TODO deploy guestbook app

# Redis Enterprise on K8s OpenShift 3.11

## Redis Enterprise K8s operator setup

https://docs.redislabs.com/latest/platforms/kubernetes/getting-started/openshift/openshift-cli/

Decide for a namespace
```
oc new-project alex-redislabs
```

Install RS K8s operator (adapt below for your namespace)
```
git clone https://github.com/RedisLabs/redis-enterprise-k8s-docs
cd redis-enterprise-k8s-docs
oc apply -f scc.yaml
oc adm policy add-scc-to-group redis-enterprise-scc  system:serviceaccounts:alex-redislabs
kubectl apply -f openshift.bundle.yaml --validate=false
```

### Deploy a 3 nodes cluster for Redis Enterprise on K8s

```
kubectl apply -f redis-enterprise-cluster.yaml
kubectl rollout status sts/demo3

# We can speak about day2
kubectl get PodDisruptionBudget -o yaml
```

Access it
```
kubectl port-forward service/demo-ui 8443
kubectl exec demo3-0 -it -- rladmin status
```

Deploy Redis DB, with persistence, replication, shards etc.
- Example persistence values
https://github.com/RedisLabs/redis-enterprise-k8s-docs/blob/master/redis_enterprise_database_api.md

```
kubectl apply -f small-db.yaml

# edit to show replica, persistence, and scaling shards (from 1 to 2 to 4)
```

Access and run memtier (change port and password, from the K8s secret generated from the deployment)
```
kubectl port-forward service/smalldb 16000
memtier_benchmark --ratio=1:4 --test-time=120 -d 150 -t 8 -c 5 --pipeline=30 --key-pattern=S:S --hide-histogram -x 1000 -s localhost -p 16000 -a ONFwzSD4
```

### TODO RedisInsight in K8S
```
kubectl port-forward service/redisinsight-service 8001
```

### Prometheus Grafana integration

kubectl port-forward service/demo3 8070
https://localhost:8070/

TODO Grafana

# Multicloud Active/Active deployment

https://docs.redislabs.com/latest/rs/concepts/intercluster-replication/
https://docs.openshift.com/container-platform/3.11/admin_guide/managing_networking.html

See also
https://github.com/Redislabs-Solution-Architects/openshift_crdb 


## Example for A/A between two namespaces
```
# Ensure pods in different namespaces can communicate to each others

oc adm pod-network join-projects --to=alex-redislabs alex-remote
```

and create CRDB (change with your PASSWORD)
```
kubectl exec demo3-0 -it -- /bin/bash
PASSWORD_K8S_NS1=...
PASSWORD_K8S_NS2=...
PASSWORD_CRDB=$PASSWORD

crdb-cli crdb create --name crdb --port 16000 --memory-size 100m \
  --instance fqdn=demo3.alex-redislabs.svc.cluster.local,url=https://demo3.alex-redislabs.svc.cluster.local:9443,username=admin@redis.io,password=$PASSWORD_K8S_NS1,replication_endpoint=crdb.alex-redislabs.svc.cluster.local:16000 \
  --instance fqdn=demoremote.alex-remote.svc.cluster.local,url=https://demoremote.alex-remote.svc.cluster.local:9443,username=admin@redis.io,password=$PASSWORD_K8S_NS2,replication_endpoint=crdb.alex-remote.svc.cluster.local:16000 \
  --sharding false --replication false --password $PASSWORD
```

## Example for A/A between "RS on OpenShift" and "RS on GCP"
```
kubectl exec demo4-0 -it -- /bin/bash
PASSWORD_K8S=...
PASSWORD_GCP=...
PASSWORD_CRDB=$PASSWORD

crdb-cli crdb create --name crdbgcp --port 17000 --memory-size 100m --encryption true \
  --instance fqdn=demo4.alex-gcp.svc.cluster.local,url=https://demo4-api.avasseur-okd.demo.redislabs.com,username=admin@redis.io,password=$PASSWORD_K8S,replication_endpoint=crdbgcp-demo4.avasseur-okd.demo.redislabs.com:443,replication_tls_sni=crdbgcp-demo4.avasseur-okd.demo.redislabs.com \
  --instance fqdn=cluster.avasseur.demo.redislabs.com,url=https://cluster.avasseur.demo.redislabs.com:9443,username=admin@redis.io,password=$PASSWORD_GCP,replication_endpoint=redis-17000.cluster.avasseur.demo.redislabs.com:17000 \
  --sharding false --replication false --password $PASSWORD
```

## Validation with redis-cli

Connect to Redis running in OpenShift:

Deploy a Redis container and connect to the local CRDB instance
```
oc new-app docker.io/redis:latest
kubectl get pods
kubectl exec redis-1-5xn62 -it -- redis-cli -h crdbgcp -p 170000
```
or you can use redis-cli from Redis Enterprise cluster node
```
kubectl exec demo4-0 -it -- redis-cli -h crdbgcp -p 17000
```

Connect to the remote instance running in GCP
```
redis-cli -h redis-17000.cluster.avasseur.demo.redislabs.com -p 17000
```


# Other Useful Things

## TLS example with traffic thru the OpenShift route as passthrough with SNI

Example of TSL connection (if DB has TLS turned on) and traffic thru OpenShift router
```
redis-cli -h ssl-16212-demo4.avasseur-okd.demo.redislabs.com -p 443 --tls --insecure --sni ssl-16212-demo4.avasseur-okd.demo.redislabs.com
```

## HowTo Force delete REDB and REC

```
kubectl get rec "demo3" -o json | jq '.metadata.finalizers = []' | kubectl replace /api/v1/rec/demo3/finalize -f -

kubectl get redb "smalldb" -o json | jq '.metadata.finalizers = []' | kubectl replace /api/v1alpha/redb/smalldb/finalize -f -

kubectl delete redb/smalldb
kubectl delete rec/demo3
```

## HowTo Recovering a cluster after restart

```
kubens alex-redislabs
kubectl patch rec demo3 --type merge --patch '{"spec":{"clusterRecovery":true}}'
kubectl describe rec

kubectl exec demo3-0 -it -- /bin/bash

rladmin status
   shows DB as: "recovery (ready)"
rlutil check
   shows db and node link error
rladmin recover all
```

## if need to run some process as root in docker  (eg apache httpd image)

oc adm policy add-scc-to-user anyuid -z default

## Other tools of interest

brew install kubectx
kubectx
kubens

KubeForwarded


