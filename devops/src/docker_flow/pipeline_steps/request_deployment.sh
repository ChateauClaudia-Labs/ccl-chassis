#!/usr/bin/env bash

# This script deploys Apodeixi to a chosen environment. I.e., it launches a container running Apodeixi with the
# appropriate configuration that, in particular, points to an environment's data volumes.
#
# To run this script, change directory to the location of this script and do something like this from a command tool
#
#               bash request_deployment.sh
#
# As a precondition, the Docker daemon must be running. To start it in WSL2 Ubuntu, do someting like:
#
#               sudo service docker start
#
export _SVC__ROOT="$( cd "$( dirname $0 )/../../../" >/dev/null 2>&1 && pwd )"
export PIPELINE_SCRIPTS="${_SVC__ROOT}/src"

source ${PIPELINE_SCRIPTS}/util/common.sh

LOGS_DIR="${PIPELINE_STEP_OUTPUT}/logs" # This is a mount of a directory in host machine, so it might already exist
if [ ! -d "${LOGS_DIR}" ]; then
  mkdir ${LOGS_DIR}
fi
export DEPLOYMENT_LOG="${LOGS_DIR}/${TIMESTAMP}_deployment.txt"

echo
echo "${_SVC__INFO_PROMPT} ---------------- Starting deployment step"
echo
# Initialize Bash's `SECONDS` timer so that at the end we can compute how long this sript took
SECONDS=0

# Comment this environment variable if we want to keep the Apodeixi container (e.g., to inspect problems) after we stop it
export REMOVE_CONTAINER_WHEN_DONE="--rm" 

# Call application-side function to set application-specific $_CFG__DEPLOYMENT_DOCKER_OPTIONS
_CFG__set_deployment_docker_options

echo "${_SVC__INFO_PROMPT} About to start Apodeixi container..."
docker run ${REMOVE_CONTAINER_WHEN_DONE} \
            ${_CFG__DEPLOYMENT_DOCKER_OPTIONS} \
            ${_CFG__DEPLOYABLE_IMAGE} & 2>/tmp/error # run in the background 
abort_on_error

echo "${_SVC__INFO_PROMPT} ...waiting for Apodeixi to start..."
sleep 3 
export APODEIXI_CONTAINER=$(docker ps -q -l) 2>/tmp/error
abort_on_error

echo "${_SVC__INFO_PROMPT} Apodeixi container ${APODEIXI_CONTAINER} up and running..."

# Run a couple of sanity checks that container is running fine and that the database was correctly mounted
#
command="apo --version && apo get assertions"
echo "[A6I_CONTAINER] Will verify that ${_CFG__DEPLOYABLE} is up and running by executing this command:"   &>> ${DEPLOYMENT_LOG}
echo "[A6I_CONTAINER]               $command"                                                   &>> ${DEPLOYMENT_LOG} 
echo                                                                                            &>> ${DEPLOYMENT_LOG}
docker exec ${APODEIXI_CONTAINER} /bin/bash -c "$command"                                       &>> ${DEPLOYMENT_LOG} 2>/tmp/error
abort_on_error
echo "${_SVC__INFO_PROMPT} Verification that ${_CFG__DEPLOYABLE} is running properly gave this output when running the command"
echo "${_SVC__INFO_PROMPT}                    $command"
echo "${_SVC__INFO_PROMPT}    (output cut to last 10 lines)"
echo
tail -n 10 ${DEPLOYMENT_LOG}

# GOTCHA - IF TESTING WITH BATS, WE MUST STOP THE CONTAINER TO PREVENT BATS FROM HANGING.
#       There are other mechanisms in the Bats documentation to avoid hanging (basically, to close file descriptor 3)
#       but they don't work in the context of Docker. Only thing I found works is stopping the container so that
#       Bats then gets unblocked and finishes up the test
if [ ! -z ${RUNNING_BATS} ]
    then
        echo "${_SVC__INFO_PROMPT} ...stopping ${_CFG__DEPLOYABLE} container..."
        echo "${_SVC__INFO_PROMPT} ...stopped ${_CFG__DEPLOYABLE} container $(docker stop ${APODEIXI_CONTAINER})"
        echo
fi

# Compute how long we took in this script
duration=$SECONDS
echo
echo "${_SVC__INFO_PROMPT} ---------------- Completed deployment step in $duration sec"
echo
echo "${_SVC__INFO_PROMPT} Check logs and distribution under ${PIPELINE_STEP_OUTPUT}"

