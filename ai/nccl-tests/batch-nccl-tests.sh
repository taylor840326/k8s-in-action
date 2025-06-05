#!/bin/bash
set -e 

nodes=${*}

if [[ -z ${nodes} ]]; then echo "empty nodes"; exit 0; fi

if [[ "$nodes" == ^* ]]; then
    file="${nodes:1}"
    if [[ -f $file ]]; then
        nos=$(cat "$file" | sed 's/^root@//')
    else
        echo "file not exists: $file" >&2
        exit 1
    fi
else
    nos=$(echo "$nodes" | sed 's/^root@//')
fi

for n in ${nos//,/ };do
  echo "node: ${n}"
  sed -e "s/name: nccl-tests-single-node-gn001/name: nccl-tests-single-node-${n//./-}/g" -e "s/gn001/${n}/g" template-nccl-tests.yaml | kubectl apply -f -
done