#!/usr/bin/env bash

export SPARK_LOCAL_DIRS="{{spark_local_dirs}}"

# Standalone cluster options
export SPARK_MASTER_OPTS="{{spark_master_opts}}"
if [ -n {{spark_worker_instances}} ]; then
  export SPARK_WORKER_INSTANCES={{spark_worker_instances}}
fi
export SPARK_WORKER_CORES={{spark_worker_cores}}
export SPARK_WORKER_MEMORY="{{spark_worker_memory}}"
export SPARK_WORKER_OPTS="{{spark_worker_opts}}"
export SPARK_DAEMON_JAVA_OPTS="{{spark_daemon_java_opts}}"

export HADOOP_HOME="/root/ephemeral-hdfs"
export SPARK_MASTER_IP={{active_master}}
export MASTER=`cat /root/spark-ec2/cluster-url`
export LOCALYTICS_ENV="{{localytics_env}}"

export SPARK_SUBMIT_LIBRARY_PATH="$SPARK_SUBMIT_LIBRARY_PATH:/root/ephemeral-hdfs/lib/native/"
export SPARK_SUBMIT_CLASSPATH="$SPARK_CLASSPATH:$SPARK_SUBMIT_CLASSPATH:/root/ephemeral-hdfs/conf"

# Bind Spark's web UIs to this machine's public EC2 hostname otherwise fallback to private IP:
export  SPARK_PUBLIC_DNS=`wget -q -O - http://169.254.169.254/latest/meta-data/local-ipv4`

# Used for YARN model
export YARN_CONF_DIR="/root/ephemeral-hdfs/conf"

# Set a high ulimit for large shuffles
ulimit -n 1000000


export ZOOKEEPER_IP=$(curl --silent consul.service.us-east-1.${LOCALYTICS_ENV}.localytics.io:8500/v1/catalog/service/{{zookeeper_stack}} | python -c 'import simplejson;import sys; c=simplejson.loads(sys.stdin.read()); print c[0]["Address"]')

export MASTER_STACK_NAME="{{master_stack_name}}"
export SPARK_DAEMON_JAVA_OPTS="-javaagent:/root/spark/lib/newrelic/newrelic.jar -Dspark.deploy.recoveryMode=ZOOKEEPER -Dspark.deploy.zookeeper.url=${ZOOKEEPER_IP}:2181 -Dspark.deploy.zookeeper.dir=/${MASTER_STACK_NAME}"

export MASTER_IPS=$(curl --silent consul.service.us-east-1.${LOCALYTICS_ENV}.localytics.io:8500/v1/catalog/service/${MASTER_STACK_NAME} | python -c 'import simplejson;import sys; c=simplejson.loads(sys.stdin.read()); print "\n".join([ n["Address"] for n in c])')

export LOCAL_IP=$(curl --silent http://169.254.169.254/latest/meta-data/local-ipv4)

for m in ${MASTER_IPS}
do
    if [ "$m" = "$LOCAL_IP" ]
    then
       export IM_A_MASTER="true" 
    fi
done

export SPARK_MASTER_IP=$(echo "get /${MASTER_STACK_NAME}/master_status" | /opt/zookeeper/zookeeper-3.4.6/bin/zkCli.sh -server ${ZOOKEEPER_IP}:2181 2>/dev/null | tail -n 2 | head -n 1 | grep -v zookeeper | grep -v null)

if [ -z "${SPARK_MASTER_IP}" ]
then
      export SPARK_MASTER_IP="${LOCAL_IP}"
elif [ "${IM_A_MASTER}" = "true" ] && [ "${SPARK_MASTER_IP}" != "${LOCAL_IP}" ]
then    
      export SPARK_MASTER_IP="${LOCAL_IP}"
fi
