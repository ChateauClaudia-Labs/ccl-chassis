#!/usr/bin/env bash

# This script conducts acceptance tests for Apodeixi by using a specific one-off virtual environment to 
# do a Conda install of an Apodeixi Windows distribution and then running tests on it.
#

export _SVC__ROOT="$( cd "$( dirname $0 )/../../../" >/dev/null 2>&1 && pwd )"
export PIPELINE_SCRIPTS="${_SVC__ROOT}/src"

source ${PIPELINE_SCRIPTS}/util/common.sh

echo
echo "${INFO_PROMPT} ---------------- Starting Windows test step"
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

echo "${INFO_PROMPT} About to prepare script to be run in  Windows test virtual environment..."

# Comment this environment variable if we want to keep the Conda virtual environment (e.g., to inspect problems) 
# after this script ends
export REMOVE_VIRTUAL_ENVIRONMENT_WHEN_DONE=1

# Comments on these options to starting the container:
#   - $APODEIXI_CONFIG_DIRECTORY environment varialbe is not needed for tests, but saves setup if we have to 
#       debug within the container
#

# To create Windows paths that work in Bash, we must transform WSL paths like
#
#       /mnt/c/Users/aleja/Documents/CodeImages/Technos/Anaconda3
#
#   to Windows Bash paths like
#
#       C:/Users/aleja/Documents/CodeImages/Technos/Anaconda3
#
#   So we use sed to replace the "/mnt/c" token by "C:", with an algorithm as per this snippet:
#
#       a=/mnt/c/Users/aleja/Documents/CodeImages/Technos/Anaconda3
#       echo $a > /tmp/AAA
#       sed -i s@/mnt/c@C:@g /tmp/AAA
#       cat /tmp/AAA
#               => C:/Users/aleja/Documents/CodeImages/Technos/Anaconda3
#
to_windows_path() {     # Expects $1 argument to be a Linux path that starts with /mnt/....
    echo $1 > /tmp/to_windows_path_${TIMESTAMP}
    sed -i s@/mnt/c@C:@g /tmp/to_windows_path_${TIMESTAMP}
    abort_on_error
    result=$(cat /tmp/to_windows_path_${TIMESTAMP})
    abort_on_error
    echo $result
}

WIN_OUTPUT_DIR=$(to_windows_path ${PIPELINE_STEP_OUTPUT})

WORKING_DIR="${PIPELINE_STEP_OUTPUT}/work"
if [ ! -d "${WORKING_DIR}" ]; then
    ## Clean up any pre-existing files
    #rm -rf ${WORKING_DIR}
    mkdir ${WORKING_DIR}
fi
#mkdir ${WORKING_DIR}

WIN_WORKING_DIR=$(to_windows_path ${WORKING_DIR})

WIN_APODEIXI_TESTDB_GIT_URL="${APODEIXI_TESTDB_GIT_URL}"
WIN__CFG__DEPLOYABLE_GIT_BRANCH="${_CFG__DEPLOYABLE_GIT_BRANCH}"
WIN__CFG__DEPLOYABLE_VERSION="${_CFG__DEPLOYABLE_VERSION}"
WIN_ERR_PROMPT="${ERR_PROMPT}"
WIN_TIMESTAMP="${TIMESTAMP}"
WIN_INJECTED_CONFIG_DIRECTORY=$(to_windows_path ${TEST_APODEIXI_CONFIG_DIRECTORY})
WIN_REMOVE_VIRTUAL_ENVIRONMENT_WHEN_DONE="${REMOVE_VIRTUAL_ENVIRONMENT_WHEN_DONE}"

echo
echo "${INFO_PROMPT} ... these environment variables will be set in the script ..."
# Environment variables to include in the Windows bash script we will be calling:
#
echo "WIN_ANACONDA_DIR:                              ${WIN_ANACONDA_DIR}" # This comes from pipeline_definition.sh
echo "WIN_OUTPUT_DIR:                                ${WIN_OUTPUT_DIR}"
echo "WIN_WORKING_DIR:                               ${WIN_WORKING_DIR}"

echo "WIN_APODEIXI_TESTDB_GIT_URL:                   ${WIN_APODEIXI_TESTDB_GIT_URL}"
echo "WIN__CFG__DEPLOYABLE_GIT_BRANCH:                       ${WIN__CFG__DEPLOYABLE_GIT_BRANCH}"
echo "WIN__CFG__DEPLOYABLE_VERSION                           ${WIN__CFG__DEPLOYABLE_VERSION}"
echo "WIN_ERR_PROMPT:                                ${WIN_ERR_PROMPT}"
echo "WIN_TIMESTAMP:                                 ${WIN_TIMESTAMP}"
echo "WIN_INJECTED_CONFIG_DIRECTORY:                 ${WIN_INJECTED_CONFIG_DIRECTORY}"
echo "WIN_REMOVE_VIRTUAL_ENVIRONMENT_WHEN_DONE:      ${WIN_REMOVE_VIRTUAL_ENVIRONMENT_WHEN_DONE}"
echo
# Now insert environment variables on top of a copy of the script, building the script we will actually run
SCRIPT_TO_RUN=${WORKING_DIR}/windows_test_$TIMESTAMP.sh
cp ${PIPELINE_SCRIPTS}/conda_flow/pipeline_steps/windows_test.sh ${SCRIPT_TO_RUN}
abort_on_error

#   GOTCHA
#
# When we apply sed on paths, we must replace sed's default delimeter "/" since the paths will also have
# that character "/", which will confuse sed. Also any other string wit "/" (e.g., "CI/CD") even if not a path.
# There are two possible remedies:
#       -Either escape the paths, changing paths like "/mnt/c/Users/..." to "\/mnt\/c\/Users..."
#       -Or use a different delimeter in sed, as long as it does not appear in paths.
#
#   I chose the latter for simplicy, using the character '#' as the sed delimeter. Hopefully no pipeline definition
#   will have paths using "#", as the calls to sed would then fail
#
echo "${INFO_PROMPT} ...inserting export WIN_ANACONDA_DIR=$(echo $WIN_ANACONDA_DIR)"
echo
sed -i "1s#^#export WIN_ANACONDA_DIR=$(echo $WIN_ANACONDA_DIR)\n#" ${SCRIPT_TO_RUN}
abort_on_error
echo
echo "      export WIN_OUTPUT_DIR=$(echo $WIN_OUTPUT_DIR)"
sed -i "1s#^#export WIN_OUTPUT_DIR=$(echo $WIN_OUTPUT_DIR)\n#" ${SCRIPT_TO_RUN}
abort_on_error
echo
echo "      export WIN_WORKING_DIR=$(echo $WIN_WORKING_DIR)"
sed -i "1s#^#export WIN_WORKING_DIR=$(echo $WIN_WORKING_DIR)\n#" ${SCRIPT_TO_RUN}
abort_on_error
echo
echo "      export WIN_APODEIXI_TESTDB_GIT_URL=$(echo $WIN_APODEIXI_TESTDB_GIT_URL)"
sed -i "1s#^#export WIN_APODEIXI_TESTDB_GIT_URL=$(echo $WIN_APODEIXI_TESTDB_GIT_URL)\n#" ${SCRIPT_TO_RUN}
abort_on_error
echo
echo "      export WIN__CFG__DEPLOYABLE_GIT_BRANCH=$(echo $WIN__CFG__DEPLOYABLE_GIT_BRANCH)"
sed -i "1s/^/export WIN__CFG__DEPLOYABLE_GIT_BRANCH=$(echo $WIN__CFG__DEPLOYABLE_GIT_BRANCH)\n/" ${SCRIPT_TO_RUN}
abort_on_error
echo
echo "      export WIN__CFG__DEPLOYABLE_VERSION=$(echo $WIN__CFG__DEPLOYABLE_VERSION)"
sed -i "1s/^/export WIN__CFG__DEPLOYABLE_VERSION=$(echo $WIN__CFG__DEPLOYABLE_VERSION)\n/" ${SCRIPT_TO_RUN}
abort_on_error
echo
echo "      export WIN_ERR_PROMPT='$(echo $WIN_ERR_PROMPT)'"
sed -i "1s#^#export WIN_ERR_PROMPT='$(echo $WIN_ERR_PROMPT)'\n#" ${SCRIPT_TO_RUN}
abort_on_error
echo
echo "      export WIN_TIMESTAMP=$(echo $WIN_TIMESTAMP)"
sed -i "1s/^/export WIN_TIMESTAMP=$(echo $WIN_TIMESTAMP)\n/" ${SCRIPT_TO_RUN}
abort_on_error
echo
echo "      export WIN_INJECTED_CONFIG_DIRECTORY=$(echo $WIN_INJECTED_CONFIG_DIRECTORY)"
sed -i "1s#^#export WIN_INJECTED_CONFIG_DIRECTORY=$(echo $WIN_INJECTED_CONFIG_DIRECTORY)\n#" ${SCRIPT_TO_RUN}
abort_on_error
echo
echo "      export WIN_REMOVE_VIRTUAL_ENVIRONMENT_WHEN_DONE=$(echo $WIN_REMOVE_VIRTUAL_ENVIRONMENT_WHEN_DONE)"
sed -i "1s/^/export WIN_REMOVE_VIRTUAL_ENVIRONMENT_WHEN_DONE=$(echo $WIN_REMOVE_VIRTUAL_ENVIRONMENT_WHEN_DONE)\n/" ${SCRIPT_TO_RUN}
abort_on_error
echo
echo "${INFO_PROMPT} ... done preparing the script that must be run in virtual environment"
echo
echo "${INFO_PROMPT} Attempting to run tests for Apodeixi branch ${_CFG__DEPLOYABLE_GIT_BRANCH} in Windows Conda virtual environment..."
echo "${INFO_PROMPT}            (this might take a 4-5 minutes...)"

# When we run the script, we must refer to it by a Windows path, even if above we manipulated it in Linux and hence have
# been referring to it by its Linux path up to now
#
WIN_SCRIPT_TO_RUN=$(to_windows_path ${SCRIPT_TO_RUN})

${WIN_BASH_EXE} ${WIN_SCRIPT_TO_RUN}                                   2>/tmp/error
abort_on_error

echo
echo "${INFO_PROMPT} Windows conda install & test was successful"

# Compute how long we took in this script
duration=$SECONDS
echo
echo "${INFO_PROMPT} ---------------- Completed Windows test step in $duration sec"
echo
echo "${INFO_PROMPT} Check logs and distribution under ${PIPELINE_STEP_OUTPUT}"
