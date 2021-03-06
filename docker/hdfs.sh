#!/bin/bash

# Copyright 2017 Banco Bilbao Vizcaya Argentaria S.A.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

set -e

# defaults
net=${NET:-"hasz"}
nodes=${NODES:-2}
volume=${VOLUME:-"/tmp/data"}

# check network existence and create it if necessary
# we need this network for the automatic service discovery in docker engine
docker network inspect ${net} > /dev/null 2>&1 && true

if [ $? -eq 1 ]; then
	net_id=$(docker network create ${net})
	echo "Created network ${net} with id ${net_id}"
fi

# bring up namenode and show its url
mkdir -p ${volume}/hdfs-namenode
hdfs_master_id=$(docker run --shm-size 2g  -d \
		-v ${volume}/hdfs-namenode:/data \
		-p 50070:50070 \
		--name hdfs-namenode \
		-h hdfs-namenode \
		--network=${net} \
		 hdfs namenode start hdfs-namenode)

sleep 2s

ip=$(docker inspect --format '{{ .NetworkSettings.Networks.'${net}'.IPAddress }}' ${hdfs_master_id})

echo Master started in:
echo http://$ip:50070

for n in $(seq 1 1 ${nodes}); do
	echo Starting node ${n}
	mkdir -p ${volume}/hdfs-datanode${n}
	datanode_id=$(docker run --shm-size 2g -d \
		-v ${volume}/hdfs-datanode${n}:/data \
		--name hdfs-datanode${n} \
		-h hdfs-datanode${n} \
		--network=${net} \
		hdfs datanode start hdfs-namenode)
done

# httpfs_node
echo Starting httpfs node
mkdir -p ${volume}/httpfs_node
datanode_id=$(docker run -d \
		-v ${volume}/httpfs_node:/data \
		-p 14000:14000 \
		-p 14001:14001 \
		--name hdfs-httpfsnode \
		-h hdfs-httpfsnode \
		--network=${net} \
		hdfs httpfs start hdfs-namenode)
