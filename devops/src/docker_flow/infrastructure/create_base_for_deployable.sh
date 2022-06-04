#!/usr/bin/env bash

# This script creates an base image from which containers from deployables can be built.
# This base image is provisioned with generic software like
#
#   - Ubuntu
#   - Python
#   - Pip
#   - GIT
#
#   The versions used are as per configuration in the pipeline definition
#
export _SVC__ROOT="$( cd "$( dirname $0 )/../../../" >/dev/null 2>&1 && pwd )"
export PIPELINE_SCRIPTS="${_SVC__ROOT}/src"

source ${PIPELINE_SCRIPTS}/util/common.sh

LOGS_DIR="${PIPELINE_STEP_OUTPUT}/logs" # This is a mount of a directory in host machine, so it might already exist
if [ ! -d "${LOGS_DIR}" ]; then
  mkdir ${LOGS_DIR}
fi
export CREATE_BASE_LOG="${LOGS_DIR}/${TIMESTAMP}_create_base.txt"

echo
echo "${_SVC__INFO_PROMPT} ---------------- Starting to create base image for ${_CFG__APPLICATION} deployables"
echo
echo "${_SVC__INFO_PROMPT} _CFG__UBUNTU_IMAGE=${_CFG__UBUNTU_IMAGE}"
echo "${_SVC__INFO_PROMPT} _CFG__PYTHON_VERSION=${_CFG__PYTHON_VERSION}"
echo
# Initialize Bash's `SECONDS` timer so that at the end we can compute how long this sript took
SECONDS=0

# GOTCHA: Docker relies on a "context folder" to build images. This "context folder" is "passed" to the Docker daemon, so all 
# files in the host that are referenced during the Docker build process must be in that folder or some sub-folder, not
# in "super directories" like ../ since they are not reachable by the Docker daemon.
#
# Therefore, we create a working folder to be used as the "context folder", and move into it any other files that are
# needed in the Docker process. That way they are all in 1 place.
export BASE_DOCKERFILE="${_SVC__ROOT}/src/docker_flow/docker/base_for_deployable/Dockerfile"
export WORK_FOLDER="${PIPELINE_STEP_OUTPUT}/provisioning_work"
if [ ! -d "${WORK_FOLDER}" ]; then
    mkdir ${WORK_FOLDER}
fi

echo "${_SVC__INFO_PROMPT} Copying Dockerfile to work folder"
cp ${BASE_DOCKERFILE} ${WORK_FOLDER} 2>/tmp/error
abort_on_error

# pip does not come with the Ubuntu python distribution, unfortunately, so we need to download this module to later help us get
# python. The Dockerfile will copy this `get-pip.py` script so that it can be invoked from within the Dockerfile building
# the base image for ${_CFG__APPLICATION} deployables.
echo "${_SVC__INFO_PROMPT} Switching directory to work folder"
cd ${WORK_FOLDER}

echo "${_SVC__INFO_PROMPT} About to downlod pip to work folder..."
echo                                                                            &>> ${CREATE_BASE_LOG}
echo "=============== Output from 'curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py"  &>> ${CREATE_BASE_LOG}
echo                                                                            &>> ${CREATE_BASE_LOG}
curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py                         &>> ${CREATE_BASE_LOG}

echo "${_SVC__INFO_PROMPT} About to build base image '${_CFG__APPLICATION_BASE_IMAGE}'..."
echo                                                                            &>> ${CREATE_BASE_LOG}
echo "=============== Output from building base image '${_CFG__APPLICATION_BASE_IMAGE}'"  &>> ${CREATE_BASE_LOG}
echo                                                                            &>> ${CREATE_BASE_LOG}
docker build --build-arg _CFG__UBUNTU_IMAGE \
            --build-arg PYTHON_VERSION=${_CFG__PYTHON_VERSION} \
            -t ${_CFG__APPLICATION_BASE_IMAGE} ${WORK_FOLDER} 1>> ${CREATE_BASE_LOG} 2>/tmp/error
abort_on_error

# Compute how long we took in this script
duration=$SECONDS
echo
echo "${_SVC__INFO_PROMPT} ---------------- Completed provisioning step in $duration sec"
echo
echo "${_SVC__INFO_PROMPT} Check logs and distribution under ${PIPELINE_STEP_OUTPUT}"