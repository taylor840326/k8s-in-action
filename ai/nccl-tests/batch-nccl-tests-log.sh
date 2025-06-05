#!/bin/bash

mkdir -p logs/nccl-tests-logs
pods=$(kubectl get pods | grep 'nccl-tests-single-node' | grep 'launcher' | grep 'Completed' | awk '{print $1}')

for pod in $pods; do
  node_name=$(kubectl get pod $pod -o=jsonpath='{.spec.nodeName}')
  kubectl logs $pod > logs/nccl-tests-logs/${node_name}_nccl_test.log
done
