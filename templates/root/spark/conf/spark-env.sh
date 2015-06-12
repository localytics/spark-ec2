#!/usr/bin/env bash

export SPARK_LOCAL_DIRS="{{spark_local_dirs}}"

# Standalone cluster options
export SPARK_MASTER_OPTS="{{spark_master_opts}}"
export SPARK_WORKER_INSTANCES={{spark_worker_instances}}
export SPARK_WORKER_CORES={{spark_worker_cores}}
export SPARK_WORKER_MEMORY="{{spark_worker_memory}}"
export SPARK_WORKER_OPTS="{{spark_worker_opts}}"
export SPARK_DAEMON_JAVA_OPTS="{{spark_daemon_java_opts}}"
export HADOOP_HOME="/root/ephemeral-hdfs"
#export SPARK_MASTER_IP={{active_master}}
export MASTER=`cat /root/spark-ec2/cluster-url`

export SPARK_SUBMIT_LIBRARY_PATH="$SPARK_SUBMIT_LIBRARY_PATH:/root/ephemeral-hdfs/lib/native/"
export SPARK_SUBMIT_CLASSPATH="$SPARK_CLASSPATH:$SPARK_SUBMIT_CLASSPATH:/root/ephemeral-hdfs/conf"

# Bind Spark's web UIs to this machine's internal EC2 hostname:
export SPARK_PUBLIC_DNS=`wget -q -O - http://169.254.169.254/latest/meta-data/local-ipv4`

# Set a high ulimit for large shuffles
ulimit -n 1000000

export ZOOKEEPER_IP=$(curl --silent consul.service.us-east-1.{{locaytics_env}}.localytics.io:8500/v1/catalog/service/{{zookeeper_stack}} | python -c 'import simplejson;import sys; c=simplejson.loads(sys.stdin.read()); print c[0]["Address"]')

export MASTER_STACK_NAME={{master_stack_name}}
export SPARK_DAEMON_JAVA_OPTS="-javaagent:/root/spark/lib/newrelic/newrelic.jar -Dspark.deploy.recoveryMode=ZOOKEEPER -Dspark.deploy.zookeeper.url=${ZOOKEEPER_IP}:2181 -Dspark.deploy.zookeeper.dir=${MASTER_STACK_NAME}"


export SPARK_MASTER_IP=$(echo 'get /{{master_stack_name}}/master_status' | /opt/zookeeper/zookeeper-3.4.6/bin/zkCli.sh -server ${ZOOKEEPER_IP}:2181 2>/dev/null | tail -n 2 | head -n 1 | grep -v zookeeper | grep -v null)

export LOCAL_IP=$(curl --silent http://169.254.169.254/latest/meta-data/local-ipv4)
if [ -z "${SPARK_MASTER_IP}" ]
  then
     export SPARK_MASTER_IP="${LOCAL_IP}"
fi
