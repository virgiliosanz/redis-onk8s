#!/bin/env bash
#
REDIS_K8S_VERSION=`curl --silent https://api.github.com/repos/RedisLabs/redis-enterprise-k8s-docs/releases/latest | grep tag_name | awk -F'"' '{print $4}'`

curl --silent -O https://raw.githubusercontent.com/RedisLabs/redis-enterprise-k8s-docs/$REDIS_K8S_VERSION/bundle.yaml
