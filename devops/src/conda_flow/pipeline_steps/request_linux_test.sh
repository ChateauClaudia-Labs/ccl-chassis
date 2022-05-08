#!/usr/bin/env bash

# This script conducts acceptance tests for Apodeixi by deploying the Apodeixi container, mounting on it
# an acceptance test database, running the tests, and producing test logs in a host folder that is mounted
# on the Apodeixi container.
#
# NB: Because of the way how Apodeixi integration tests are designed, each of them will run on a dedicated
#       Apodeixi environment with a dedicated test-specific `apodeixi_config.toml`. However, for the test harness
#       to start an initial `apodeixi_config.toml` is needed, which is expected to be already provisioned
#       in the test database, and is injected into the Apodeixi container via a mount.
#
# As a precondition, the Docker daemon must be running. To start it in WSL2 Ubuntu, do someting like:
#
#               sudo service docker start
#

export _SVC__ROOT="$( cd "$( dirname $0 )/../../../" >/dev/null 2>&1 && pwd )"
export PIPELINE_SCRIPTS="${_SVC__ROOT}/src"

source ${PIPELINE_SCRIPTS}/util/common.sh

echo
echo "${INFO_PROMPT} ---------------- Starting Linux test step"
echo
# Initialize Bash's `SECONDS` timer so that at the end we can compute how long this sript took
SECONDS=0

# We expect the test database to alreay have an `apodeixi_config.toml` file geared to development-time testing.
# That means that the paths referenced in that `apodeixi_config.toml` file are expected to include hard-coded
# directories for the developer's machine.
#
# These hard-coded directories in the host won't work when the tests are run inside the Apodeixi container, so we 
# will have to replace them by paths in the container file system. However, we don't want to modify the
# test database's `apodeixi_config.toml` file since its host hard-coded paths are needed at development time.
# Therefore, the container will apply this logic when running testrun.sh:
#
#   1. Clone the GIT repo that contains the test database into /home/work, creating /home/work/apodeixi-testdb inside
#      the container
#   2. Rely on the environment variable $INJECTED_CONFIG_DIRECTORY to locate the folder where the Apodeixi configuration
#      file resides. 
#      This environment variable is needed to address the following problem with Apodeixi's test harness, and specifcially by
#      apodeixi.testing_framework.a6i_skeleton_test.py:
#
#           The test harness by default assumes that the Apodeixi configuration is found in 
#
#                    '../../../../test_db'
#
#           with the path relative to that of `a6i_skeleton_test.py` in the container, which is 
#
#                   /usr/local/lib/python3.9/dist-packages/apodeixi/testing_framework/a6i_skeleton_test.py
#
#      because of the way how pip installed Apodeixi inside the container. 
#
#      This is addresed by:
#           - setting the environment variable $INJECTED_CONFIG_DIRECTORY to /home/apodeixi_testdb_config
#           - this will cause the test harness to look for Apodeixi's configuration in the folder $INJECTED_CONFIG_DIRECTORY
#           - additionally, read the value of another environment variable, $TEST_APODEIXI_CONFIG_DIRECTORY, from the
#             pipeline definition (in pipeline_album/<pipeline_id>/pipeline_definition.sh)
#           - this way the pipeline's choice for what apodeixi_config.toml to use for testing will come from looking
#             in $TEST_APODEIXI_CONFIG_DIRECTORY in the host
#           - lastly, we mount $TEST_APODEIXI_CONFIG_DIRECTORY as /home/apodeixi_testdb_config in the container, which is
#             where the container-run test harness will expect it (since that's the value of $INJECTED_CONFIG_DIRECTORY)
#

echo "${INFO_PROMPT} About to start Linux test container..."

# Comment this environment variable if we want to keep the test container (e.g., to inspect problems) after this script ends
export REMOVE_CONTAINER_WHEN_DONE=1

# Comments on these options to starting the container:
#   - $APODEIXI_CONFIG_DIRECTORY environment varialbe is not needed for tests, but saves setup if we have to 
#       debug within the container
#
docker run  -e TIMESTAMP=${TIMESTAMP} \
            -e _CFG__DEPLOYABLE_VERSION=${_CFG__DEPLOYABLE_VERSION} -e _CFG__DEPLOYABLE_GIT_BRANCH=${_CFG__DEPLOYABLE_GIT_BRANCH} \
            -e APODEIXI_TESTDB_GIT_URL=${APODEIXI_TESTDB_GIT_URL} \
            -e INJECTED_CONFIG_DIRECTORY=/home/${_CFG__DEPLOYABLE}_testdb_config \
            -e APODEIXI_CONFIG_DIRECTORY=/home/${_CFG__DEPLOYABLE}_testdb_config \
            --hostname "APO-LINUX-TEST-${TIMESTAMP}" \
            -v ${PIPELINE_STEP_OUTPUT}:/home/output \
            -v ${PIPELINE_SCRIPTS}/conda_flow/pipeline_steps:/home/scripts \
            -v $TEST_APODEIXI_CONFIG_DIRECTORY:/home/${_CFG__DEPLOYABLE}_testdb_config \
            ${A6I_CONDABUILD_SERVER} & 2>/tmp/error # run in the background so rest of this script can proceed
abort_on_error

echo "${INFO_PROMPT} ...waiting for Linux test container to start..."
sleep 3

export LINUX_TEST_CONTAINER=$(docker ps -q -l) 2>/tmp/error
abort_on_error

echo
echo "${INFO_PROMPT} Linux test container ${LINUX_TEST_CONTAINER} up and running..."
echo
echo "${INFO_PROMPT} Attempting to run tests for Apodeixi branch ${_CFG__DEPLOYABLE_GIT_BRANCH} using container ${LINUX_TEST_CONTAINER}..."
echo "${INFO_PROMPT}            (this might take a 3-4 minutes...)"

docker exec ${LINUX_TEST_CONTAINER} /bin/bash /home/scripts/linux_test.sh 2>/tmp/error
# We don't use the generic function ./common.sh::abort_on_error because we want to warn the user that a rogue container
# was left running, so we manually write the code to catch and handle the exception
if [[ $? != 0 ]]; then
    error=$(</tmp/error)
    echo "${ERR_PROMPT} ${error}"
    echo
    echo "${ERR_PROMPT} Due to above error, cleanup wasn't done. Container ${LINUX_TEST_CONTAINER} needs to be manually stopped"
    echo 
    echo "${ERR_PROMPT} For more detail on error, check logs under ${PIPELINE_STEP_OUTPUT}"
    unblock_bats
    exit 1
fi

echo
echo "${INFO_PROMPT} Linux conda install & test was successful"

# GOTCHA - IF TESTING WITH BATS, WE MUST STOP THE CONTAINER TO PREVENT BATS FROM HANGING.
#       There are other mechanisms in the Bats documentation to avoid hanging (basically, to close file descriptor 3)
#       but they don't work in the context of Docker. Only thing I found works is stopping the container so that
#       Bats then gets unblocked and finishes up the test
if [ ! -z ${REMOVE_CONTAINER_WHEN_DONE} ] || [ ! -z ${RUNNING_BATS} ]
    then
        echo "${INFO_PROMPT} ...stopping test container..."
        echo "${INFO_PROMPT} ...stopped test container $(docker stop ${LINUX_TEST_CONTAINER})"
        echo "${INFO_PROMPT} ...removed test container $(docker rm ${LINUX_TEST_CONTAINER})"
        echo
fi

# Compute how long we took in this script
duration=$SECONDS
echo
echo "${INFO_PROMPT} ---------------- Completed Linux test step in $duration sec"
echo
echo "${INFO_PROMPT} Check logs and distribution under ${PIPELINE_STEP_OUTPUT}"
