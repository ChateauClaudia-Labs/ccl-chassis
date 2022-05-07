#!/usr/bin/env bash

export CCL_DEVOPS_SERVICE_ROOT="$( cd "$( dirname $0 )/../../../" >/dev/null 2>&1 && pwd )"

export PIPELINE_SCRIPTS="${CCL_DEVOPS_SERVICE_ROOT}/src"

source ${PIPELINE_SCRIPTS}/util/common.sh

# Comment this environment variable if we want to keep the build container (e.g., to inspect problems) after using build is over
export REMOVE_CONTAINER_WHEN_DONE="--rm" 

# Run build in build container
#
echo
echo "${INFO_PROMPT} ---------------- Starting build step"
# Initialize Bash's `SECONDS` timer so that at the end we can compute how long this sript took
SECONDS=0

echo "${INFO_PROMPT} ... Determining approach for how container can access the GIT repo:"
if [ ! -z ${MOUNT_APODEIXI_GIT_PROJECT} ]
    then
        echo "${INFO_PROMPT}        => by mounting this drive:"
        echo "${INFO_PROMPT}        => ${APODEIXI_GIT_URL}"
        if [ ! -d ${APODEIXI_GIT_URL} ]
            then
                echo "${ERR_PROMPT} Directory doesn't exist, so can't mount it:"
                echo "      ${APODEIXI_GIT_URL}"
                echo
                echo "${ERR_PROMPT} Aborting build..."
                exit 1
        fi
        export APODEIXI_URL_CLONED_BY_CONTAINER="/home/apodeixi"
        export GIT_REPO_MOUNT_DOCKER_OPTION="-v ${APODEIXI_GIT_URL}:${APODEIXI_URL_CLONED_BY_CONTAINER}"
    else
        echo "${INFO_PROMPT}        => from this URL:"
        echo "${INFO_PROMPT}        => ${APODEIXI_GIT_URL}"
        export APODEIXI_URL_CLONED_BY_CONTAINER="${APODEIXI_GIT_URL}"
fi

echo
echo "${INFO_PROMPT} About to start build server container..."
docker run ${REMOVE_CONTAINER_WHEN_DONE} \
            --hostname "APO-BUILDER-${TIMESTAMP}" \
            -e TIMESTAMP=${TIMESTAMP} -e APODEIXI_GIT_BRANCH=${APODEIXI_GIT_BRANCH} \
            -e APODEIXI_GIT_URL=${APODEIXI_URL_CLONED_BY_CONTAINER} \
            -v ${PIPELINE_STEP_OUTPUT}:/home/output -v ${PIPELINE_SCRIPTS}/docker_flow/pipeline_steps:/home/scripts \
            ${GIT_REPO_MOUNT_DOCKER_OPTION} \
            ${A6I_BUILD_SERVER} & 2>/tmp/error  # run in the background so rest of this script can proceed
abort_on_error

echo "${INFO_PROMPT} ...waiting for build server to start..."
sleep 3

export BUILD_CONTAINER=$(docker ps -q -l) 2>/tmp/error
abort_on_error

echo "${INFO_PROMPT} Build server container ${BUILD_CONTAINER} up and running..."
echo "${INFO_PROMPT} ...attempting to build Apodeixi branch ${APODEIXI_GIT_BRANCH}..."

echo "${INFO_PROMPT} ...will build Apodeixi using container ${BUILD_CONTAINER}..."
docker exec ${BUILD_CONTAINER} /bin/bash /home/scripts/build.sh 2>/tmp/error
# We don't use the generic function ./common.sh::abort_on_error because we want to warn the user that a rogue container
# was left running, so we manually write the code to catch and handle the exception
if [[ $? != 0 ]]; then
    error=$(</tmp/error)
    echo "${ERR_PROMPT} ${error}"
    echo "${ERR_PROMPT} Due to above error, cleanup wasn't done. Container ${BUILD_CONTAINER} needs to be manually stopped"
    echo "${ERR_PROMPT} For more detail on error, check logs under ${PIPELINE_STEP_OUTPUT}"
    exit 1
fi

echo "${INFO_PROMPT} Build was successful"
echo "${INFO_PROMPT} ...stopping build container..."
echo "${INFO_PROMPT} ...stopped build container $(docker stop ${BUILD_CONTAINER})"
echo

# Compute how long we took in this script
duration=$SECONDS
echo "${INFO_PROMPT} ---------------- Completed build step in $duration sec"
echo
echo "${INFO_PROMPT} Check logs and distribution under ${PIPELINE_STEP_OUTPUT}"
