#!/usr/bin/env bash

set -euo pipefail


if [ $(id -un) != root ]; then
  sudo -u root -EH ${0} "${@}"
  exit 0
fi


pv=${1?'PV Required !'}
namespace=${2?'NameSpace Required !'}

path=$(mount | grep ${1} | sed -E 's/\/dev\/rbd[0-9]+\s+on (.*mount).+/\1/g')

if [ -f /mnt/backups/${namespace}/${pv}.tgz ]; then
  echo "File exist !!!"
  continue
else
  sudo mkdir -p /mnt/backups/${namespace}
  cd ${path}
  sleep 7
  sudo tar -zcvf "/mnt/backups/${namespace}/${pv}.tgz" .
fi

echo OK