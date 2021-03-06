#!/usr/bin/env bash

# This script conducts acceptance tests for the deployable (assumed to be a Python module) by using a specific 
# one-off virtual environment to do a Conda install of a Windows distribution for the deployable and then running tests on it.
#

export _SVC__ROOT="$( cd "$( dirname $0 )/../../../" >/dev/null 2>&1 && pwd )"
export PIPELINE_SCRIPTS="${_SVC__ROOT}/src"

source ${PIPELINE_SCRIPTS}/util/common.sh

echo
echo "${_SVC__INFO_PROMPT} ---------------- Starting Windows test step"
echo
# Initialize Bash's `SECONDS` timer so that at the end we can compute how long this sript took
SECONDS=0

echo "${_SVC__INFO_PROMPT} About to prepare script to be run in  Windows test virtual environment..."

# Comment this environment variable if we want to keep the Conda virtual environment (e.g., to inspect problems) 
# after this script ends
export REMOVE_VIRTUAL_ENVIRONMENT_WHEN_DONE=1

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

WIN_TESTDB_GIT_URL="${_CFG__TESTDB_GIT_URL}"
WIN_TESTDB_REPO_NAME="${_CFG__TESTDB_REPO_NAME}"

WIN_DEPLOYABLE_GIT_BRANCH="${_CFG__DEPLOYABLE_GIT_BRANCH}"
WIN_DEPLOYABLE_VERSION="${_CFG__DEPLOYABLE_VERSION}"
WIN_DEPLOYABLE="${_CFG__DEPLOYABLE}"
WIN_ERR_PROMPT="${_SVC__ERR_PROMPT}"
WIN_TIMESTAMP="${TIMESTAMP}"
WIN_REMOVE_VIRTUAL_ENVIRONMENT_WHEN_DONE="${REMOVE_VIRTUAL_ENVIRONMENT_WHEN_DONE}"

echo
echo "${_SVC__INFO_PROMPT} ... these environment variables will be set in the script ..."
# Environment variables to include in the Windows bash script we will be calling:
#
echo "WIN_ANACONDA_DIR:                             ${_CFG__WIN_ANACONDA_DIR}" # This comes from pipeline_definition.sh
echo "WIN_OUTPUT_DIR:                               ${WIN_OUTPUT_DIR}"
echo "WIN_WORKING_DIR:                              ${WIN_WORKING_DIR}"

echo "WIN_TESTDB_GIT_URL:                           ${WIN_TESTDB_GIT_URL}"
echo "WIN_TESTDB_REPO_NAME:                         ${WIN_TESTDB_REPO_NAME}"
echo "WIN_DEPLOYABLE_GIT_BRANCH:                    ${WIN_DEPLOYABLE_GIT_BRANCH}"
echo "WIN_DEPLOYABLE_VERSION:                       ${WIN_DEPLOYABLE_VERSION}"
echo "WIN_DEPLOYABLE:                               ${WIN_DEPLOYABLE}"
echo "WIN_ERR_PROMPT:                               ${WIN_ERR_PROMPT}"
echo "WIN_TIMESTAMP:                                ${WIN_TIMESTAMP}"
echo "_CFG__DEPLOYABLE:                             ${_CFG__DEPLOYABLE}"


echo "WIN_REMOVE_VIRTUAL_ENVIRONMENT_WHEN_DONE:     ${WIN_REMOVE_VIRTUAL_ENVIRONMENT_WHEN_DONE}"
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

_CFG__apply_windows_test_conda_options ${SCRIPT_TO_RUN}

echo "${_SVC__INFO_PROMPT} ...inserting export WIN_ANACONDA_DIR=$(echo $_CFG__WIN_ANACONDA_DIR)"
echo
sed -i "1s#^#export WIN_ANACONDA_DIR=$(echo $_CFG__WIN_ANACONDA_DIR)\n#" ${SCRIPT_TO_RUN}
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
echo "      export WIN_TESTDB_GIT_URL=$(echo $WIN_TESTDB_GIT_URL)"
sed -i "1s#^#export WIN_TESTDB_GIT_URL=$(echo $WIN_TESTDB_GIT_URL)\n#" ${SCRIPT_TO_RUN}
abort_on_error
echo
echo "      export WIN_TESTDB_REPO_NAME=$(echo $WIN_TESTDB_REPO_NAME)"
sed -i "1s#^#export WIN_TESTDB_REPO_NAME=$(echo $WIN_TESTDB_REPO_NAME)\n#" ${SCRIPT_TO_RUN}
abort_on_error
echo
echo "      export WIN_DEPLOYABLE_GIT_BRANCH=$(echo $WIN_DEPLOYABLE_GIT_BRANCH)"
sed -i "1s/^/export WIN_DEPLOYABLE_GIT_BRANCH=$(echo $WIN_DEPLOYABLE_GIT_BRANCH)\n/" ${SCRIPT_TO_RUN}
abort_on_error
echo
echo "      export WIN_DEPLOYABLE_VERSION=$(echo $WIN_DEPLOYABLE_VERSION)"
sed -i "1s/^/export WIN_DEPLOYABLE_VERSION=$(echo $WIN_DEPLOYABLE_VERSION)\n/" ${SCRIPT_TO_RUN}
abort_on_error
echo
echo "      export WIN_DEPLOYABLE=$(echo $WIN_DEPLOYABLE)"
sed -i "1s/^/export WIN_DEPLOYABLE=$(echo $WIN_DEPLOYABLE)\n/" ${SCRIPT_TO_RUN}
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
echo "      export _CFG__DEPLOYABLE=$(echo $_CFG__DEPLOYABLE)"
sed -i "1s/^/export _CFG__DEPLOYABLE=$(echo $_CFG__DEPLOYABLE)\n/" ${SCRIPT_TO_RUN}
abort_on_error
echo
echo "      export WIN_REMOVE_VIRTUAL_ENVIRONMENT_WHEN_DONE=$(echo $WIN_REMOVE_VIRTUAL_ENVIRONMENT_WHEN_DONE)"
sed -i "1s/^/export WIN_REMOVE_VIRTUAL_ENVIRONMENT_WHEN_DONE=$(echo $WIN_REMOVE_VIRTUAL_ENVIRONMENT_WHEN_DONE)\n/" ${SCRIPT_TO_RUN}
abort_on_error
echo
echo "${_SVC__INFO_PROMPT} ... done preparing the script that must be run in virtual environment"
echo
echo "${_SVC__INFO_PROMPT} Attempting to run tests for ${_CFG__DEPLOYABLE} branch ${_CFG__DEPLOYABLE_GIT_BRANCH} in Windows Conda virtual environment..."
echo "${_SVC__INFO_PROMPT}            (this might take a 4-5 minutes...)"

# When we run the script, we must refer to it by a Windows path, even if above we manipulated it in Linux and hence have
# been referring to it by its Linux path up to now
#
WIN_SCRIPT_TO_RUN=$(to_windows_path ${SCRIPT_TO_RUN})

${_CFG__WIN_BASH_EXE} ${WIN_SCRIPT_TO_RUN}                                   2>/tmp/error
abort_on_error

echo
echo "${_SVC__INFO_PROMPT} Windows conda install & test was successful"

# Compute how long we took in this script
duration=$SECONDS
echo
echo "${_SVC__INFO_PROMPT} ---------------- Completed Windows test step in $duration sec"
echo
echo "${_SVC__INFO_PROMPT} Check logs and distribution under ${PIPELINE_STEP_OUTPUT}"
