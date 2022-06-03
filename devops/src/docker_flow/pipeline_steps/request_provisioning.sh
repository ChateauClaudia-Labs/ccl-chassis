#!/usr/bin/env bash

# This script creates an image for a container where ${_CFG__DEPLOYABLE} runs, and provisions it with the relevant software.
#
# To run this script, change directory to the location of this script and do something like this from a command tool
#
#               bash request_provisioning.sh
#
# As a precondition, the Docker daemon must be running. To start it in WSL2 Ubuntu, do someting like:
#
#               sudo service docker start
#
# After the image is built, to inspect it from within you can start a shell as root in the container, like this:
#
#               docker run -it --rm ${_CFG__DEPLOYABLE} /bin/bash

export _SVC__ROOT="$( cd "$( dirname $0 )/../../../" >/dev/null 2>&1 && pwd )"
export PIPELINE_SCRIPTS="${_SVC__ROOT}/src"

source ${PIPELINE_SCRIPTS}/util/common.sh

LOGS_DIR="${PIPELINE_STEP_OUTPUT}/logs" # This is a mount of a directory in host machine, so it might already exist
if [ ! -d "${LOGS_DIR}" ]; then
  mkdir ${LOGS_DIR}
fi
export PROVISIONING_LOG="${LOGS_DIR}/${TIMESTAMP}_provisioning.txt"

echo
echo "${_SVC__INFO_PROMPT} ---------------- Starting provisioning step"
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
export PROVISIONING_DOCKERFILE="${_SVC__ROOT}/src/docker_flow/docker/container_for_deployable/Dockerfile"
export WORK_FOLDER="${PIPELINE_STEP_OUTPUT}/provisioning_work"
if [ ! -d "${WORK_FOLDER}" ]; then
    mkdir ${WORK_FOLDER}
fi

echo "${_SVC__INFO_PROMPT} Copying Dockerfile to work folder"
cp ${PROVISIONING_DOCKERFILE} ${WORK_FOLDER} 2>/tmp/error
abort_on_error

echo "${_SVC__INFO_PROMPT} Copying ${_CFG__DEPLOYABLE} distribution to work folder"
cp ${PIPELINE_STEP_INTAKE}/dist/${_CFG__DEPLOYABLE}-${_CFG__DEPLOYABLE_VERSION}-py3-none-any.whl ${WORK_FOLDER} 2>/tmp/error
abort_on_error

# pip does not come with the Ubuntu python distribution, unfortunately, so we need to download this module to later help us get
# python. The Dockerfile will copy this `get-pip.py` script so that it can be invoked from within the ${_CFG__DEPLOYABLE} container
# in order to provision pip
echo "${_SVC__INFO_PROMPT} Switching directory to work folder"
cd ${WORK_FOLDER}

echo "${_SVC__INFO_PROMPT} About to downlod pip to work folder..."
echo                                                                            &>> ${PROVISIONING_LOG}
echo "=============== Output from 'curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py"  &>> ${PROVISIONING_LOG}
echo                                                                            &>> ${PROVISIONING_LOG}
curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py                         &>> ${PROVISIONING_LOG}

echo "${_SVC__INFO_PROMPT} About to build ${_CFG__DEPLOYABLE} image '${_CFG__DEPLOYABLE_IMAGE}'..."
echo                                                                            &>> ${PROVISIONING_LOG}
echo "=============== Output from building ${_CFG__DEPLOYABLE} image '${_CFG__DEPLOYABLE_IMAGE}'"  &>> ${PROVISIONING_LOG}
echo                                                                            &>> ${PROVISIONING_LOG}
docker build --build-arg _CFG__UBUNTU_IMAGE \
            --build-arg PYTHON_VERSION=${_CFG__PYTHON_VERSION} \
            --build-arg _CFG__DEPLOYABLE_VERSION \
            --build-arg _CFG__DEPLOYABLE \
            -t ${_CFG__DEPLOYABLE_IMAGE} ${WORK_FOLDER} 1>> ${PROVISIONING_LOG} 2>/tmp/error
abort_on_error

# Compute how long we took in this script
duration=$SECONDS
echo
echo "${_SVC__INFO_PROMPT} ---------------- Completed provisioning step in $duration sec"
echo
echo "${_SVC__INFO_PROMPT} Check logs and distribution under ${PIPELINE_STEP_OUTPUT}"