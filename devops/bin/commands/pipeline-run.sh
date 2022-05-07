#!/usr/bin/env bash

# Script to implement the behavior of the `apdo pipeline run` command for the `apdo` CLI
source ${CCL_DEVOPS_SERVICE_ROOT}/bin/util/apdo-common.sh

# Check that a command  passed as argument $1. Set the error message to use in $ERROR_MSG
export ERR_MSG="pipeline ID must be given. Try 'apdo pipeline list' to view a list of available pipeline IDs"
cli_argument_exists $1

export PIPELINE_ID="$1" # For example, '1001'. This uniquely identifies the pipeline 
export PIPELINE_NAME="${PIPELINE_ID}_pipeline" # For example, '1001_pipeline'. This is a folder with parameters defining a particular pipeline 

# Check that there is a pipeline for this id
cli_pipeline_exists ${CCL_DEVOPS_CONFIG_PIPELINE_ALBUM} ${PIPELINE_NAME}

# Check that pipeline folder includes a pipeline definition and a script to run end-to-end pipeline
cli_pipeline_def_exists ${CCL_DEVOPS_CONFIG_PIPELINE_ALBUM} ${PIPELINE_NAME}
cli_pipeline_run_exists ${CCL_DEVOPS_CONFIG_PIPELINE_ALBUM} ${PIPELINE_NAME}

# Get definition (really more of a config) of the pipeline we are running
source "${CCL_DEVOPS_CONFIG_PIPELINE_ALBUM}/${PIPELINE_NAME}/pipeline_definition.sh"

# GOTCHA: In case $RUN_TIMESTAMP is set, reset it since we want to do a brand new run with its own 
#           dedicated timestamp. We don't want to log into a prior run's log folder
export RUN_TIMESTAMP="$(date +"%y%m%d.%H%M%S")"
LOGS_DIR="${CCL_DEVOPS_CONFIG_PIPELINE_ALBUM}/${PIPELINE_NAME}/output/${RUN_TIMESTAMP}_pipeline_run/logs" 
if [ ! -d "${LOGS_DIR}" ]; then
    mkdir -p ${LOGS_DIR} # -p flag creates intermediate directories if they are missing too
fi
export PIPELINE_LOG="${LOGS_DIR}/MASTER_LOG.txt"

START=$SECONDS
echo "${INFO_PROMPT} Running pipeline ${PIPELINE_ID}"
echo "${INFO_PROMPT}"
echo "${INFO_PROMPT}    Pipeline description: $(pipeline_short_description)"
echo "${INFO_PROMPT}"

# Run the end-to-end pipeline. Use 'source' so that we inherit this script's environment variables
source "${CCL_DEVOPS_CONFIG_PIPELINE_ALBUM}/${PIPELINE_NAME}/execute_pipeline.sh"

echo
END=$SECONDS
duration=$((${END} - ${START}))
echo "${INFO_PROMPT} DONE - pipeline ${PIPELINE_ID} completed in $duration sec"
echo
echo "${INFO_PROMPT} See logs at:"
echo "${INFO_PROMPT}        ${LOGS_DIR}"
echo

