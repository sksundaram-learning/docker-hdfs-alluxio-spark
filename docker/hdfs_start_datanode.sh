#!/usr/bin/env bash

node=${1:-0}
volume=${2:-"/tmp/data${node}"}
name=${3:-"namenode"}

createNetwork() {
  sudo docker network inspect alluxio > /dev/null 2>&1

  if [ $? -eq 1 ]; then
    local network=$(sudo docker network create alluxio)
    echo "Created network alluxio $network"
  fi
}

createNetwork

mkdir -p $volume

sudo docker run -d -v ${volume}:/data --name hdfs-data${node} -h hdfs-data${node} --network=alluxio hdfs datanode start ${name}