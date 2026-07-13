#!/bin/bash

# ==============================================
# Defatult values
# ==============================================
NODES_LIST=(1)
CPUS_LIST=(4) # Use only one CPU value
ACCOUNT="p_lv_dda_26"
RUNS=1
RESERVATION_ID=""
OUTPUT_DIR="$(realpath $(dirname $0))/output"
VENV_DIR="/projects/p_lv_dda_26/.venv"
SPARK_TEMPLATE="/projects/p_lv_dda_26/10-DistributedComputing-III/template/spark"
# ==============================================


# Function to display the help message
print_help() {
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "Options:"
    echo "  -a <account>        ZIH ID (Default=p_lv_digitization_25)"
    echo "  -z <reservation_id> Reservation ID. Do not use, if there is no reservation."
    echo "  -n <nodes>          Number of Nodes to run the program with. Comma-separated list of nodes. (Default=1)"
    echo "  -c <cpus>           Number of CPUs to run the program with. Comma-separated list of CPUs. (Default=4)"
    echo "  -r <runs>           Number runs per configuration. (Default=1)"
    echo "  -o <output_dir>     Specify the output directory, where results will be saved."
    echo "  -h                  Display this help message and exit."
    echo
    echo "Example:"
    echo "  $0 -a <account_id> -r <reservation_id> -n node1,node2,node3 -c cpu1,cpu2 -r runs -o /path/to/output_dir"
    exit 1
}

# Parse command-line options
while getopts "a:z:o:n:c:r:h" flag; do
    case "${flag}" in
        a) ACCOUNT="${OPTARG}";;
        z) RESERVATION_ID="${OPTARG}";;
        o) OUTPUT_DIR=$(realpath ${OPTARG});;
        n) IFS=',' read -r -a NODES_LIST <<< "${OPTARG}";;
        c) IFS=',' read -r -a CPUS_LIST <<< "${OPTARG}";;
        r) RUNS="${OPTARG}";;
        h) print_help;;
        *) print_help;;
    esac
done


# Create output directory
mkdir -p $OUTPUT_DIR

# Initialize dependency variable
JOB_DEPENDENCY="true" # true/false
DEPENDENCY=""

# ===============================================================
# Sbatch job
# ===============================================================
# Loop through nodes and CPUs
for NUM_NODES in "${NODES_LIST[@]}"; do
  for NUM_CPUS in "${CPUS_LIST[@]}"; do
    for (( RUN_i=1; RUN_i<="$RUNS"; RUN_i++ )); do

    NAME="${NUM_NODES}nodes_${NUM_CPUS}cpus_${RUN_i}run"
    
    # SBATCH script content
    SBATCH_SCRIPT="#!/bin/bash
#SBATCH --job-name=spark_perf_${NAME}
#SBATCH --output=${OUTPUT_DIR}/${NAME}_%j/job.out
#SBATCH --nodes=$NUM_NODES
#SBATCH --cpus-per-task=$((NUM_CPUS+3))
#SBATCH --mem=10G
#SBATCH --time=00:30:00
#SBATCH --account=${ACCOUNT}

export JOB_DIR=\"${OUTPUT_DIR}/${NAME}_\${SLURM_JOBID}\"
mkdir -p \$JOB_DIR

export NUM_CPUS=${NUM_CPUS}
export SPARK_TEMPLATE=\"${SPARK_TEMPLATE}\"
export OUTPUT_DIR=\"${OUTPUT_DIR}\"

module load development/24.04 GCC/13.2.0
module load Spark/3.5.0-hadoop3

# Activate virtual environment
source $VENV_DIR/bin/activate

# Your testing commands go here
echo 'Running tests on ${NUM_NODES} nodes with ${NUM_CPUS} CPUs per node'
echo '=================================================================='

source ./spark.sh

sleep 5s
"
    # Create a temporary sbatch script file
    TEMP_SBATCH_SCRIPT=$(mktemp)
    echo "$SBATCH_SCRIPT" > $TEMP_SBATCH_SCRIPT
    
    cp $TEMP_SBATCH_SCRIPT $OUTPUT_DIR/ 
 
    SBATCH_CMD="sbatch"

    # Submit the job with dependency
    if [[ "$JOB_DEPENDENCY" == "true" ]]; then
      if ! [ -z "$DEPENDENCY" ]; then
        SBATCH_CMD="$SBATCH_CMD --dependency=afterany:$DEPENDENCY"
      fi
    fi

    if [[ "$RESERVATION_ID" != "" ]]; then
        SBATCH_CMD="$SBATCH_CMD --reservation=$RESERVATION_ID"
    fi

    # Final sbatch command
    SBATCH_CMD="$SBATCH_CMD $TEMP_SBATCH_SCRIPT"
    
    # Submit the job
    OUT=`$SBATCH_CMD`
    echo $OUT

    # Set dependency to the last job ID
    DEPENDENCY=$(echo $OUT | awk '{print $4}')

    # Cleanup temporary sbatch script file
    rm $TEMP_SBATCH_SCRIPT
    done
  done
done

# ===============================================================
# Post processing
# ===============================================================
SBATCH_SCRIPT="#!/bin/bash
#SBATCH --job-name=postprocess
#SBATCH --output=${OUTPUT_DIR}/post_process_job.out
#SBATCH --nodes=1
#SBATCH --cpus-per-task=2
#SBATCH --mem=1G
#SBATCH --time=00:05:00
#SBATCH --account=${ACCOUNT}

module load release/24.04 GCC/13.2.0 Python/3.11.5

# Activate virtual environment
source $VENV_DIR/bin/activate

echo 'Processing results'
python Solution_post_process.py \"$OUTPUT_DIR/results.txt\" \"$OUTPUT_DIR\"
"

# Create a temporary sbatch script file
TEMP_SBATCH_SCRIPT=$(mktemp)
echo "$SBATCH_SCRIPT" > $TEMP_SBATCH_SCRIPT
SBATCH_CMD="sbatch --dependency=afterany:$DEPENDENCY $TEMP_SBATCH_SCRIPT"

# Submit the job
OUT=`$SBATCH_CMD`
echo "Submitted batch job for postprocessing"
echo $OUT

# End of the script