bash oc-deploy-spark-job.sh wordcount "--master spark://spark-master:7077 --driver-memory 1g --executor-memory 2g --packages org.alluxio:alluxio-core-client:1.4.0 http://hdfs-httpfs:14000/webhdfs/v1/jobs/spark-wordcount.jar?op=OPEN&user.name=root -i alluxio://alluxio-master:19998/data/sample-1g"

bash oc-deploy-spark-job.sh wordcount "--master spark://spark-master:7077 --driver-memory 1g --executor-memory 2g --packages org.alluxio:alluxio-core-client:1.4.0 http://hdfs-httpfs:14000/webhdfs/v1/jobs/spark-wordcount.jar?op=OPEN&user.name=root -i alluxio://alluxio-master:19998/data/sample-2g2"