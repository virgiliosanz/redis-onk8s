#!/bin/bash

kubens -c
kubectl get rec
PASSWORD=`kubectl get secret demo3 --template={{.data.password}} | base64 -D`


curl -s -k https://demo3-api.avasseur-okd.demo.redislabs.com/v1/cluster -u admin@redis.io:$PASSWORD | jq .