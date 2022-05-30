#!/usr/bin/env bash

# This script creates an image for a container that can be used to build ${_CFG__DEPLOYABLE}
#
#
# As a precondition, the Docker daemon must be running. To start it in WSL2 Ubuntu, do someting like:
#
#               sudo service docker start
#
#
export _SVC__ROOT="$( cd "$( dirname $0 )/../../../" >/dev/null 2>&1 && pwd )"
export PIPELINE_SCRIPTS="${_SVC__ROOT}/src"

source ${PIPELINE_SCRIPTS}/util/common.sh

LOGS_DIR="${PIPELINE_STEP_OUTPUT}/logs" # This is a mount of a directory in host machine, so it might already exist
if [ ! -d "${LOGS_DIR}" ]; then
  mkdir ${LOGS_DIR}
fi
export SETUP_INFRA_LOG="${LOGS_DIR}/${TIMESTAMP}_setup_infra.txt"

# Initialize Bash's `SECONDS` timer so that at the end we can compute how long this sript took
SECONDS=0

echo
echo "${_SVC__INFO_PROMPT} ---------------- Building build server's image '${_CFG__BUILD_SERVER}'"
echo
echo "${_SVC__INFO_PROMPT} _CFG__UBUNTU_IMAGE=${_CFG__UBUNTU_IMAGE}"
echo "${_SVC__INFO_PROMPT} _CFG__UBUNTU_PYTHON_PACKAGE=${_CFG__UBUNTU_PYTHON_PACKAGE}"
echo

export DOCKERFILE_DIR=${PIPELINE_SCRIPTS}/docker_flow/docker/build_server
cd ${DOCKERFILE_DIR}
echo "${_SVC__INFO_PROMPT} Current directory is ${DOCKERFILE_DIR}"
echo
echo "${_SVC__INFO_PROMPT} Running Docker build..."
echo
docker build --build-arg _CFG__UBUNTU_IMAGE --build-arg _CFG__UBUNTU_PYTHON_PACKAGE -t ${_CFG__BUILD_SERVER} . 1>> ${SETUP_INFRA_LOG} 2>/tmp/error
abort_on_error

# Compute how long we took in this script
duration=$SECONDS
echo
echo "${_SVC__INFO_PROMPT} ---------------- Completed creating image for build server in $duration sec"
echo


