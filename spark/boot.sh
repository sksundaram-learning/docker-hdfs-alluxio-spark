#!/usr/bin/env bash

cluster_name="$3"

set -o errexit
set -o pipefail
set -o nounset
set -o errtrace


# main script params

node="$1"
action="$2"


if [ "${cluster_name}z" == "z" ]; then
	cluster_name=${HOSTNAME}
fi
SPARK_MASTER_HOST=${cluster_name}

set +o nounset

export SPARK_HOME=/opt/spark
export SPARK_CONF_DIR=${SPARK_HOME}/conf

# SPARK_MASTER_PORT is also defined by openshift to a value incompatible 
export SPARK_MASTER_PORT=7077
export SPARK_MASTER_WEBUI_PORT=${SPARK_MASTER_WEBUI_PORT:-8080}

export SPARK_WORKER_MEMORY=${SPARK_WORKER_MEMORY:-"1g"}
export SPARK_WORKER_PORT=${SPARK_WORKER_PORT:-35000}
export SPARK_WORKER_WEBUI_PORT=${SPARK_WORKER_WEBUI_PORT:-8081}

export SPARK_DAEMON_MEMORY=${SPARK_DAEMON_MEMORY:-"1g"}

mkdir -p ${SPARK_HOME}/logs/

master_node() {
	local action="${1}"
	local cluster_name="${2}"
	
	case $action in
		start)
			${SPARK_HOME}/sbin/start-master.sh
		;;
		stop)
			${SPARK_HOME}/sbin/stop-master.sh
		;;
		status)
			# I would love a status report
			echo "Not implemented"
		;;
		*)
			echo "Action not supported"
			;;
	esac

}

slave_node() {
	local action="${1}"
	
	case $action in
		start)
			${SPARK_HOME}/sbin/start-slave.sh --host $(hostname -f) spark://${SPARK_MASTER_HOST}:${SPARK_MASTER_PORT}
			;;
		stop)
			${SPARK_HOME}/sbin/stop-slave.sh
			;;
		status)
			# I would love a status report
			echo "Not implemented"
			;;
		*)
			echo "Action not supported"
			;;
	esac
}

spark_handler() {
	local node="$1"
	local action="$2"

	echo "spark_handler():${node} ${action}"
	case $node in
		master)
			master_node ${action}
		;;
		slave)
			slave_node ${action}
		;;
	esac
}

setup_username() {
	export USER_ID=$(id -u)
	export GROUP_ID=$(id -g)
	cat /etc/passwd > /tmp/passwd
	echo "openshift:x:${USER_ID}:${GROUP_ID}:OpenShift Dynamic user:${ALLUXIO_PREFIX}:/bin/bash" >> /tmp/passwd
	export LD_PRELOAD=/usr/lib64/libnss_wrapper.so
	export NSS_WRAPPER_PASSWD=/tmp/passwd
	export NSS_WRAPPER_GROUP=/etc/group
}

shut_down() {
	echo "Calling shutdown! $1"
	spark_handler ${node} stop
}

trap "shut_down sigkill" SIGKILL
trap "shut_down sigterm" SIGTERM
trap "shut_down sighup" SIGHUP
trap "shut_down sigint" SIGINT
# trap "shut_down sigexit" EXIT

setup_username

echo "The ${node} is swtching to ${action}"
spark_handler ${node} ${action} ${cluster_name}

sleep 2s
tail -f /opt/spark/logs/*
