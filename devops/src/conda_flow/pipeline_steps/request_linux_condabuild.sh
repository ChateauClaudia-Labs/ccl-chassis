#!/usr/bin/env bash

export CCL_DEVOPS_SERVICE_ROOT="$( cd "$( dirname $0 )/../../../" >/dev/null 2>&1 && pwd )"

export PIPELINE_SCRIPTS="${CCL_DEVOPS_SERVICE_ROOT}/src"

source ${PIPELINE_SCRIPTS}/util/common.sh

# Comment this environment variable if we want to keep the build container (e.g., to inspect problems) after using build is over
export REMOVE_CONTAINER_WHEN_DONE="--rm" 

# Run build in build container
#
echo
echo "${INFO_PROMPT} ---------------- Starting Linux conda build step"
echo
echo "${INFO_PROMPT} CONDA_RECIPE               =   ${CONDA_RECIPE}"
echo "${INFO_PROMPT} A6I_CONDABUILD_SERVER      =   ${A6I_CONDABUILD_SERVER}"

# Initialize Bash's `SECONDS` timer so that at the end we can compute how long this sript took
SECONDS=0

export CONDA_RECIPE_DIR=${PIPELINE_SCRIPTS}/conda_flow/conda_recipes/${CONDA_RECIPE}

echo
echo "${INFO_PROMPT} About to start condabuild server container..."
docker run ${REMOVE_CONTAINER_WHEN_DONE} \
            --hostname "APO-CONDABUILDER-${TIMESTAMP}" \
            -e TIMESTAMP=${TIMESTAMP} -e APODEIXI_VERSION=${APODEIXI_VERSION} \
            -e HOST_CONDA_RECIPE_DIR=${CONDA_RECIPE_DIR} \
            -v ${PIPELINE_STEP_OUTPUT}:/home/output \
            -v ${PIPELINE_SCRIPTS}/conda_flow/pipeline_steps:/home/scripts \
            -v ${CONDA_RECIPE_DIR}:/home/conda_build_recipe \
            ${A6I_CONDABUILD_SERVER} & 2>/tmp/error  # run in the background so rest of this script can proceed
abort_on_error

echo "${INFO_PROMPT} ...waiting for condabuild server to start..."
sleep 3

export CONDABUILD_CONTAINER=$(docker ps -q -l) 2>/tmp/error
abort_on_error

echo "${INFO_PROMPT} Conda build server container ${CONDABUILD_CONTAINER} up and running..."
echo "${INFO_PROMPT} ...attempting to build Apodeixi branch ${APODEIXI_GIT_BRANCH}..."

echo "${INFO_PROMPT} ...building Apodeixi using container ${CONDABUILD_CONTAINER}... (this will take a 4-5 minutes)"
echo

docker exec ${CONDABUILD_CONTAINER} /bin/bash /home/scripts/linux_condabuild.sh 2>/tmp/error
# We don't use the generic function ./common.sh::abort_on_error because we want to warn the user that a rogue container
# was left running, so we manually write the code to catch and handle the exception
if [[ $? != 0 ]]; then
    error=$(</tmp/error)
    echo "${ERR_PROMPT} ${error}"
    echo "${ERR_PROMPT} Due to above error, cleanup wasn't done. Container ${CONDABUILD_CONTAINER} needs to be manually stopped"
    echo "${ERR_PROMPT} For more detail on error, check logs under ${PIPELINE_STEP_OUTPUT}"
    exit 1
fi

echo "${INFO_PROMPT} Conda build was successful"
echo "${INFO_PROMPT} Output was saved to ${PIPELINE_STEP_OUTPUT}/dist"
echo
echo "${INFO_PROMPT} ...stopping conda build container..."
echo "${INFO_PROMPT} ...stopped conda build container $(docker stop ${CONDABUILD_CONTAINER})"
echo

# Compute how long we took in this script
duration=$SECONDS
echo "${INFO_PROMPT} ---------------- Completed Linux conda build step in $duration sec"
echo
echo "${INFO_PROMPT} Check logs and distribution under ${PIPELINE_STEP_OUTPUT}"
