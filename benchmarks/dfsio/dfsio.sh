#!/bin/bash

oc_dir=${OC_DIR:-"../../oc"}
executor_cores=${EXECUTOR_CORES:-"1"}
total_executor_cores=${TOTAL_EXECUTOR_CORES:-"7"}

function write() {
  local write_type="$1"
  local num_files="$2"
  local file_size="$3"

  local job_name=$(echo "dfsio-write-${write_type}-${num_files}-${file_size}" | sed "s/_/-/g" | tr A-Z a-z)

  pushd $oc_dir
    exec bash oc-deploy-spark-job.sh $job_name \
      --master spark://spark-master:7077 \
      --class com.bbva.spark.benchmarks.dfsio.TestDFSIO \
      --total-executor-cores $total_executor_cores \
      --executor-cores $executor_cores \
      --driver-memory 1g \
      --executor-memory 1g \
      --conf spark.locality.wait=30s \
      --conf spark.driver.extraJavaOptions=-Dalluxio.user.file.writetype.default=$write_type \
      --conf spark.executor.extraJavaOptions=-Dalluxio.user.file.writetype.default=$write_type \
      --packages org.alluxio:alluxio-core-client:1.4.0 \
      "http://hdfs-httpfs:14000/webhdfs/v1/jobs/dfsio.jar?op=OPEN&user.name=openshift" \
      write --numFiles $num_files --fileSize $file_size --outputDir  alluxio://alluxio-master:19998/benchmarks/DFSIO
  popd
}


function read() {
  local read_type="$1"
  local num_files="$2"
  local file_size="$3"

  local job_name=$(echo "dfsio-read-${read_type}-${num_files}-${file_size}" | sed "s/_/-/g" | tr A-Z a-z)

  pushd $oc_dir
    exec bash oc-deploy-spark-job.sh $job_name \
      --master spark://spark-master:7077 \
      --class com.bbva.spark.benchmarks.dfsio.TestDFSIO \
      --total-executor-cores $total_executor_cores \
      --executor-cores $executor_cores \
      --driver-memory 1g \
      --executor-memory 1g \
      --conf spark.locality.wait=30s \
      --conf spark.driver.extraJavaOptions=-Dalluxio.user.file.readtype.default=$read_type \
      --conf spark.executor.extraJavaOptions=-Dalluxio.user.file.readtype.default=$read_type \
      --packages org.alluxio:alluxio-core-client:1.4.0 \
      "http://hdfs-httpfs:14000/webhdfs/v1/jobs/dfsio.jar?op=OPEN&user.name=openshift" \
      read --numFiles $num_files --fileSize $file_size --inputDir  alluxio://alluxio-master:19998/benchmarks/DFSIO
  popd
}

function clean() {
  local job_name="${1:-"dfsio-clean"}"

  pushd $oc_dir
    exec bash oc-deploy-spark-job.sh $job_name \
      --master spark://spark-master:7077 \
      --class com.bbva.spark.benchmarks.dfsio.TestDFSIO \
      --driver-memory 1g \
      --executor-memory 1g \
      --total-executor-cores 1 \
      --executor-cores 1 \
      --packages org.alluxio:alluxio-core-client:1.4.0 \
      "http://hdfs-httpfs:14000/webhdfs/v1/jobs/dfsio.jar?op=OPEN&user.name=openshift" \
      clean --outputDir  alluxio://alluxio-master:19998/benchmarks/DFSIO
    popd
}