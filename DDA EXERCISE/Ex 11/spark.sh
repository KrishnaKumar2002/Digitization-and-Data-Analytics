#!/bin/bash
set -e 

mkdir -p $OUTPUT_DIR

# Initialize framework configuration
source framework-configure.sh \
  --framework spark \
  --template ${SPARK_TEMPLATE} \
  --destination ./myconf

# Use first node to run master processes
SPARK_MASTER_HOST=$(scontrol show hostname $SLURM_NODELIST | head -1)
export SPARK_MASTER_HOST=${SPARK_MASTER_HOST}
# Create a distinct port number
SLURM_JOBID_LAST_CHAR="${SLURM_JOBID: -4}"
export SPARK_MASTER_PORT=$(( 7077 + 10#$SLURM_JOBID_LAST_CHAR ))
while [[ "${SPARK_MASTER_PORT:0:1}" == "0" ]]; do
  SPARK_MASTER_PORT=$((10#$SPARK_MASTER_PORT + 1000))
  export SPARK_MASTER_PORT=${SPARK_MASTER_PORT: -4}
done
# Add information to the configuration file
SPARK_ENV_FILE="$SPARK_CONF_DIR/spark-env.sh"
echo "export SPARK_MASTER_HOST=$SPARK_MASTER_HOST" >> $SPARK_ENV_FILE
echo "export SPARK_MASTER_PORT=$SPARK_MASTER_PORT" >> $SPARK_ENV_FILE
echo "export PYSPARK_PYTHON=$(which python)" >> $SPARK_ENV_FILE
echo "export PYSPARK_DRIVER_PYTHON=$(which python)" >> $SPARK_ENV_FILE
sed -i 's!^\(export SPARK_WORKER_CORES=\).*!\1'$NUM_CPUS'!g' $SPARK_ENV_FILE
sed -i 's!^\(export SPARK_EXECUTOR_CORES=\).*!\1'$NUM_CPUS'!g' $SPARK_ENV_FILE

# Start the standalone cluster
$SPARK_HOME/sbin/start-master.sh
$SPARK_HOME/sbin/start-worker.sh spark://${SPARK_MASTER_HOST}:${SPARK_MASTER_PORT}

sleep 5s

##########################################################################
# Task
##########################################################################
# Submit the pyspark application to the already started standalone cluster
spark-submit \
    --master spark://${SPARK_MASTER_HOST}:${SPARK_MASTER_PORT} \
    --deploy-mode client \
    --conf spark.standalone.submit.waitAppCompletion=true \
    --conf spark.executor.cores=$NUM_CPUS \
    --conf spark.default.parallelism=$NUM_CPUS \
    app.py "$OUTPUT_DIR"

sleep 5s

$SPARK_HOME/sbin/stop-worker.sh
$SPARK_HOME/sbin/stop-master.sh
