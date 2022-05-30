#!/usr/bin/env bash

# This script conducts acceptance tests for ${_CFG__DEPLOYABLE} by deploying the ${_CFG__DEPLOYABLE} container, mounting on it
# an acceptance test database, running the tests, and producing test logs in a host folder that is mounted
# on the ${_CFG__DEPLOYABLE} container.
#
# To run this script, change directory to the location of this script and do something like this from a command tool
#
#               bash request_testrun.sh
#
# As a precondition, the Docker daemon must be running. To start it in WSL2 Ubuntu, do someting like:
#
#               sudo service docker start
#

export _SVC__ROOT="$( cd "$( dirname $0 )/../../../" >/dev/null 2>&1 && pwd )"
export PIPELINE_SCRIPTS="${_SVC__ROOT}/src"

source ${PIPELINE_SCRIPTS}/util/common.sh

echo
echo "${_SVC__INFO_PROMPT} ---------------- Starting testrun step"
echo
# Initialize Bash's `SECONDS` timer so that at the end we can compute how long this sript took
SECONDS=0

echo "${_SVC__INFO_PROMPT} About to start ${_CFG__DEPLOYABLE} test container..."

# Comment this environment variable if we want to keep the test container (e.g., to inspect problems) after this script ends
export REMOVE_CONTAINER_WHEN_DONE=1

# Call application-side function to set application-specific $_CFG__TESTRUN_DOCKER_OPTIONS
_CFG__set_testrun_docker_options

docker run  -e TIMESTAMP=${TIMESTAMP} \
            -e _CFG__DEPLOYABLE_GIT_BRANCH=${_CFG__DEPLOYABLE_GIT_BRANCH} \
            -e _CFG__DEPLOYABLE=${_CFG__DEPLOYABLE} \
            -e _CFG__UBUNTU_PYTHON_PACKAGE=${_CFG__UBUNTU_PYTHON_PACKAGE} \
            --hostname "${_CFG__DEPLOYABLE}-TESTRUNNER-${TIMESTAMP}" \
            -v ${PIPELINE_STEP_OUTPUT}:/home/output \
            -v ${PIPELINE_SCRIPTS}/docker_flow/pipeline_steps:/home/scripts \
            ${_CFG__TESTRUN_DOCKER_OPTIONS} \
            ${_CFG__DEPLOYABLE_IMAGE} & 2>/tmp/error # run in the background so rest of this script can proceed
abort_on_error

echo "${_SVC__INFO_PROMPT} ...waiting for ${_CFG__DEPLOYABLE} test container to start..."
sleep 3

export CONTAINER_FOR_DEPLOYABLE=$(docker ps -q -l) 2>/tmp/error
abort_on_error

echo
echo "${_SVC__INFO_PROMPT} ${_CFG__DEPLOYABLE} test container ${CONTAINER_FOR_DEPLOYABLE} up and running..."
echo
echo "${_SVC__INFO_PROMPT} Attempting to run tests for ${_CFG__DEPLOYABLE} branch ${_CFG__DEPLOYABLE_GIT_BRANCH} using container ${CONTAINER_FOR_DEPLOYABLE}..."
echo "${_SVC__INFO_PROMPT}            (this might take a 1-2 minutes...)"

docker exec ${CONTAINER_FOR_DEPLOYABLE} /bin/bash /home/scripts/testrun.sh 2>/tmp/error
# We don't use the generic function ./common.sh::abort_on_error because we want to warn the user that a rogue container
# was left running, so we manually write the code to catch and handle the exception
if [[ $? != 0 ]]; then
    error=$(</tmp/error)
    echo "${_SVC__ERR_PROMPT} ${error}"
    echo
    echo "${_SVC__ERR_PROMPT} Due to above error, cleanup wasn't done. Container ${CONTAINER_FOR_DEPLOYABLE} needs to be manually stopped"
    echo 
    echo "${_SVC__ERR_PROMPT} For more detail on error, check logs under ${PIPELINE_STEP_OUTPUT}"
    unblock_bats
    exit 1
fi
echo
echo "${_SVC__INFO_PROMPT} Testrun was successful"

# GOTCHA - IF TESTING WITH BATS, WE MUST STOP THE CONTAINER TO PREVENT BATS FROM HANGING.
#       There are other mechanisms in the Bats documentation to avoid hanging (basically, to close file descriptor 3)
#       but they don't work in the context of Docker. Only thing I found works is stopping the container so that
#       Bats then gets unblocked and finishes up the test
if [ ! -z ${REMOVE_CONTAINER_WHEN_DONE} ] || [ ! -z ${RUNNING_BATS} ]
    then
        echo "${_SVC__INFO_PROMPT} ...stopping test container..."
        echo "${_SVC__INFO_PROMPT} ...stopped test container $(docker stop ${CONTAINER_FOR_DEPLOYABLE})"
        echo "${_SVC__INFO_PROMPT} ...removed test container $(docker rm ${CONTAINER_FOR_DEPLOYABLE})"
        echo
fi

# Compute how long we took in this script
duration=$SECONDS
echo
echo "${_SVC__INFO_PROMPT} ---------------- Completed testrun step in $duration sec"
echo
echo "${_SVC__INFO_PROMPT} Check logs and distribution under ${PIPELINE_STEP_OUTPUT}"
