#!/usr/bin/env bash

export _SVC__ROOT="$( cd "$( dirname $0 )/../../../" >/dev/null 2>&1 && pwd )"

export PIPELINE_SCRIPTS="${_SVC__ROOT}/src"

source ${PIPELINE_SCRIPTS}/util/common.sh

# Comment this environment variable if we want to keep the build container (e.g., to inspect problems) after using build is over
export REMOVE_CONTAINER_WHEN_DONE="--rm" 

# Run build in build container
#
echo
echo "${_SVC__INFO_PROMPT} ---------------- Starting build step"
echo
echo "${_SVC__INFO_PROMPT} Deployable: ${_CFG__DEPLOYABLE}"
# Initialize Bash's `SECONDS` timer so that at the end we can compute how long this sript took
SECONDS=0

# Call application-side function to set application-specific $_CFG__BUILD_DOCKER_OPTIONS
_CFG__set_build_docker_options

echo
echo "${_SVC__INFO_PROMPT} About to start build server container..."
echo
docker run ${REMOVE_CONTAINER_WHEN_DONE} \
            --hostname "${_CFG__DEPLOYABLE}-BUILDER-${TIMESTAMP}" \
            -e TIMESTAMP=${TIMESTAMP} \
            -e _CFG__DEPLOYABLE_GIT_BRANCH=${_CFG__DEPLOYABLE_GIT_BRANCH} \
            -e _CFG__DEPLOYABLE=${_CFG__DEPLOYABLE} \
            ${_CFG__BUILD_DOCKER_OPTIONS} \
            -v ${PIPELINE_STEP_OUTPUT}:/home/output -v ${PIPELINE_SCRIPTS}/docker_flow/pipeline_steps:/home/scripts \
            ${_CFG__BUILD_SERVER} & 2>/tmp/error  # run in the background so rest of this script can proceed
abort_on_error

echo "${_SVC__INFO_PROMPT} ...waiting for build server to start..."
sleep 3

export BUILD_CONTAINER=$(docker ps -q -l) 2>/tmp/error
abort_on_error

echo "${_SVC__INFO_PROMPT} Build server container ${BUILD_CONTAINER} up and running..."
echo "${_SVC__INFO_PROMPT} ...attempting to build ${_CFG__DEPLOYABLE} branch ${_CFG__DEPLOYABLE_GIT_BRANCH}..."

echo "${_SVC__INFO_PROMPT} ...will build ${_CFG__DEPLOYABLE} using container ${BUILD_CONTAINER}..."
docker exec ${BUILD_CONTAINER} /bin/bash /home/scripts/build.sh 2>/tmp/error
# We don't use the generic function ./common.sh::abort_on_error because we want to warn the user that a rogue container
# was left running, so we manually write the code to catch and handle the exception
if [[ $? != 0 ]]; then
    error=$(</tmp/error)
    echo "${_SVC__ERR_PROMPT} ${error}"
    echo "${_SVC__ERR_PROMPT} Due to above error, cleanup wasn't done. Container ${BUILD_CONTAINER} needs to be manually stopped"
    echo "${_SVC__ERR_PROMPT} For more detail on error, check logs under ${PIPELINE_STEP_OUTPUT}"
    unblock_bats_in_build
    exit 1
fi

echo "${_SVC__INFO_PROMPT} Build was successful"
echo "${_SVC__INFO_PROMPT} ...stopping build container..."
echo "${_SVC__INFO_PROMPT} ...stopped build container $(docker stop ${BUILD_CONTAINER})"
echo

# Compute how long we took in this script
duration=$SECONDS
echo "${_SVC__INFO_PROMPT} ---------------- Completed build step in $duration sec"
echo
echo "${_SVC__INFO_PROMPT} Check logs and distribution under ${PIPELINE_STEP_OUTPUT}"
