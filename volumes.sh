#!/usr/bin/env bash

set -ex

namespace=${1?'NameSpace Required !'}

scale_pod() {
	kubectl -n ${namespace} scale ${1} ${2}  --replicas 0	
}
up_pod() {
  kubectl -n ${namespace} scale ${1} ${2}  --replicas 1
}

for item in $(kubectl  get volumeattachments.storage.k8s.io | awk '{print $3}' | sed '1d'); do
  if [ $(kubectl get pv ${item} -o json | jq -r '.spec.claimRef.namespace') == "${namespace}" ]; then
    csi=$(kubectl get volumeattachments.storage.k8s.io -o json | jq -r ".items[] | select(.spec.source.persistentVolumeName == \"${item}\")" | jq -r '.metadata.name')
    node=$(kubectl  get volumeattachments.storage.k8s.io ${csi} -o json | jq -r '.spec.nodeName')
    pvc=$(kubectl get pv ${item} -o json | jq -r '.spec.claimRef.name')
    pod=$(kubectl get -n ${namespace} pods -o json | jq -r ".items | map(select(.spec.volumes | map(select(.persistentVolumeClaim.claimName == \"${pvc}\")) | select(length > 0)) | .metadata.name) | join(\",\")")   
    if ! [ -z "${pod}" ]; then
      printf "Need scale before backup: "
      read answer
      if [ ${answer} == "y" ] || [ ${answer} == "Y" ]; then
        kind=$(kubectl get pods -n ${namespace} ${pod} -o json | jq -r '.metadata.ownerReferences[].kind')
        name=$(kubectl get pods -n ${namespace} ${pod} -o json | jq -r '.metadata.ownerReferences[].name')
        scale_pod "${kind}" "${name}"      	
        ssh elofun@${node} ./backup.sh "${item}" "${namespace}"
      else
        exit 1
      fi
    fi
    kind=$(kubectl get pods -n ${namespace} ${pod} -o json | jq -r '.metadata.ownerReferences[].kind')
    name=$(kubectl get pods -n ${namespace} ${pod} -o json | jq -r '.metadata.ownerReferences[].name')
    up_pod "${kind}" "${name}"
  else
    echo "This NameSpace has no backup plan yet !!!"
  fi
done
