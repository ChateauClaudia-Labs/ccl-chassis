#!/usr/bin/env bash

# This script creates an image for a container that can be used to build a conda package for Apodeixi
#
#
# As a precondition, the Docker daemon must be running. To start it in WSL2 Ubuntu, do someting like:
#
#               sudo service docker start
#
#
export CCL_DEVOPS_SERVICE_ROOT="$( cd "$( dirname $0 )/../../../" >/dev/null 2>&1 && pwd )"
export PIPELINE_SCRIPTS="${CCL_DEVOPS_SERVICE_ROOT}/src"

source ${PIPELINE_SCRIPTS}/util/common.sh

LOGS_DIR="${PIPELINE_STEP_OUTPUT}/logs" # This is a mount of a directory in host machine, so it might already exist
if [ ! -d "${LOGS_DIR}" ]; then
  mkdir ${LOGS_DIR}
fi
export SETUP_INFRA_LOG="${LOGS_DIR}/${TIMESTAMP}_setup_infra.txt"

# Initialize Bash's `SECONDS` timer so that at the end we can compute how long this sript took
SECONDS=0

echo
echo "${INFO_PROMPT} ---------------- Building condabuild server's image '${A6I_CONDABUILD_SERVER}'"
echo
echo "${INFO_PROMPT} UBUNTU_IMAGE=${UBUNTU_IMAGE}"
echo "${INFO_PROMPT} ANACONDA_VERSION=${ANACONDA_VERSION}"
echo

export DOCKERFILE_DIR=${PIPELINE_SCRIPTS}/conda_flow/docker/condabuild_server
cd ${DOCKERFILE_DIR}
echo "${INFO_PROMPT} Current directory is ${DOCKERFILE_DIR}"
echo
echo "${INFO_PROMPT} Running Docker build... (this may take a few minutes)"
echo
docker build    --build-arg UBUNTU_IMAGE \
                --build-arg ANACONDA_VERSION \
                --build-arg ANACONDA_SHA \
                -t ${A6I_CONDABUILD_SERVER} . 1>> ${SETUP_INFRA_LOG} 2>/tmp/error
abort_on_error

# Compute how long we took in this script
duration=$SECONDS
echo
echo "${INFO_PROMPT} ---------------- Completed creating image for condabuild server in $duration sec"
echo


