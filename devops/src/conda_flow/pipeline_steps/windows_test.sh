#!/usr/bin/env bash

# This script is meant to run in a Windows host, doing operations in a special-purpose Conda virtual environment.
#
# CONVENTION:
#           Environment variables that begin with "WIN_" refer to Windows paths/concepts and should have
#       been "passed" by the caller, where "passed" is accomplished by: 
#       - The caller makes a copy of this script
#       - The caller modified the copy by inserting at the top lines to set each of those "WIN_..." environment
#           variables
#       - Caller then invokes that modified copy of this script, as opposed to invoking this script.
#       All other environment variables in this script are defined within this script.
#
LOGS_DIR="${WIN_OUTPUT_DIR}/logs" 
if [ ! -d "${LOGS_DIR}" ]; then
  mkdir ${LOGS_DIR}
fi

export TEST_LOG="${LOGS_DIR}/${WIN_TIMESTAMP}_windows_test.txt"

abort_testrun_on_error() {
if [[ $? != 0 ]]; then
    #error=$(</tmp/error)
    echo 
    echo "${WIN_ERR_PROMPT} ${error}"                                                       &>> ${TEST_LOG}
    # Signal error again, this time for caller to catch, but limiting error to caller to just the last 5 lines.
    # If caller wants to see all the error message, caller can go to the logs
    echo "Aborting testrun. Here is the error message (cut down to last 5 lines):"
    echo 
    tail -n 5 /tmp/error
    echo 
    #  Before exiting, make sure we save the full errors to the test log, so we can debug later
    cat /tmp/error >> ${TEST_LOG}
    exit 1
fi    
}

# Want to find /c/Users/aleja/Documents/CodeImages/Technos/Anaconda3/Scripts/conda
export PATH=${WIN_ANACONDA_DIR}/Scripts:$PATH      
DISTRIBUTION_FOLDER=${WIN_OUTPUT_DIR}/dist/win-64
if [ ! -d ${DISTRIBUTION_FOLDER} ]
    then
        error="Distribution folder ${DISTRIBUTION_FOLDER} does not exist. Aborting"
        echo "[WIN_TEST_VIRTUAL_ENV] $error"      &>> ${TEST_LOG}
        echo $error                             
        exit 1
fi
# Pick the first file in the distribution folder that seems to be s distribution for the deployable
# for the version of interest
#
echo "[WIN_TEST_VIRTUAL_ENV] Looking for a file ${WIN_DEPLOYABLE}-${WIN_DEPLOYABLE_VERSION}* in  ${DISTRIBUTION_FOLDER}" &>> ${TEST_LOG}
export DEPLOYABLE_DISTRIBUTION=$(echo $(ls ${DISTRIBUTION_FOLDER} | grep "${WIN_DEPLOYABLE}-${WIN_DEPLOYABLE_VERSION}") | awk '{print $1}') \
                1>> ${TEST_LOG} 2>/tmp/error
abort_testrun_on_error
if [ -z ${DEPLOYABLE_DISTRIBUTION} ]
    then
        error="Could not find ${WIN_DEPLOYABLE} distribution. Aborting"
        echo "[WIN_TEST_VIRTUAL_ENV] $error"       &>> ${TEST_LOG}
        echo $error                             
        exit 1
fi

# NB: Redirecting with &>> appends both standard output and standard error to the file

echo "[WIN_TEST_VIRTUAL_ENV] ---------- Conda Windows install & test logs ---------- $(date) ---------- "       &>> ${TEST_LOG}
echo                                                                                                        &>> ${TEST_LOG}

echo "[WIN_TEST_VIRTUAL_ENV] Hostname=$(hostname)"                                                            &>> ${TEST_LOG}
echo                                                                                                        &>> ${TEST_LOG}
cd ${WIN_WORKING_DIR}                                                                                           &>> ${TEST_LOG}
echo "[WIN_TEST_VIRTUAL_ENV] Current directory is $(pwd)"                                                     &>> ${TEST_LOG}
echo "[WIN_TEST_VIRTUAL_ENV] Current user is is $(whoami)"                                                    &>> ${TEST_LOG}
echo "[WIN_TEST_VIRTUAL_ENV] Distribution is ${DEPLOYABLE_DISTRIBUTION}"                                        &>> ${TEST_LOG}
echo                                                                                                        &>> ${TEST_LOG}


echo "[WIN_TEST_VIRTUAL_ENV] =========== Installing ${WIN_DEPLOYABLE} and its dependencies..."                         &>> ${TEST_LOG}
# Initialize Bash's `SECONDS` timer so that at the end we can compute how long this action takes
SECONDS=0
echo "[WIN_TEST_VIRTUAL_ENV]  ... creating virtual environment..."                                            &>> ${TEST_LOG}
echo                                                                                                        &>> ${TEST_LOG}
# Conda virtual environment for installation and test
export VIRTUAL_ENV="test_${WIN_TIMESTAMP}"
yes "y" | conda create -n ${VIRTUAL_ENV}                                                          1>> ${TEST_LOG} 2>/tmp/error
abort_testrun_on_error
echo "[A6I_WIN_BLD_VIRTUAL_ENV] Virtual environment is ${VIRTUAL_ENV}"                              &>> ${TEST_LOG}
echo                                                                                                &>> ${TEST_LOG}

### GOTCHA
#           It is virtually impossible to initialize conda in a container.
#           That's because the 'conda init' presumes a login shell
#       Workaround, is to always 'conda <command> -n <environment>' for all conda commands, instead
#       of doing 'conda activate <env>'

echo                                                                                                        &>> ${TEST_LOG}
echo "[WIN_TEST_VIRTUAL_ENV]  ... conda install -n ${VIRTUAL_ENV} ${DEPLOYABLE_DISTRIBUTION}..."                 &>> ${TEST_LOG}
echo                                                                                                        &>> ${TEST_LOG}
yes " y" | conda install -n ${VIRTUAL_ENV} ${DISTRIBUTION_FOLDER}/${DEPLOYABLE_DISTRIBUTION}           1>> ${TEST_LOG} 2>/tmp/error
abort_testrun_on_error
echo                                                                                                        &>> ${TEST_LOG}
# At this point the virtual environment if pretty empty - it only has the deployable,
# but lacks Python and lacks dependencies.
# Both will be brought in if we install python
echo "[WIN_TEST_VIRTUAL_ENV]  ... now installing ${WIN_DEPLOYABLE} dependencies..."                             &>> ${TEST_LOG}
echo                                                                                                        &>> ${TEST_LOG}
yes " y" | conda install -n ${VIRTUAL_ENV} python                                                           &>> ${TEST_LOG}
echo                                                                                                        &>> ${TEST_LOG}
echo                                                                                                        &>> ${TEST_LOG}
duration=$SECONDS                                                                                           &>> ${TEST_LOG}
echo "[WIN_TEST_VIRTUAL_ENV] ...${DEPLOYABLE_DISTRIBUTION} successfully installed in container in $duration sec" &>> ${TEST_LOG}
echo                                                                                                        &>> ${TEST_LOG}


echo "[WIN_TEST_VIRTUAL_ENV] =========== Installing test database..."                                         &>> ${TEST_LOG}
echo                                                                                                        &>> ${TEST_LOG}
# GOTCHA
#       Our working folder is very nested in the file hiearchy, and if we insist on doing a git clone on that
#       working folder we will probably get "Filename too long" error messages like these:
#
#                   error: unable to create file results_data/8101/foreign_key.milestones_big_rock_version/fkey.ml_2_br.T7_cli_output          post --timestamp              _EXPECTED.txt: Filename too long
#                   fatal: unable to checkout working tree
#                   warning: Clone succeeded, but checkout failed.
#
#   So to address this, we will do git clone of the test db into a different folder
#
export TESTDB_REPO_PARENT_DIR="$(cd ~/tmp && pwd)/${VIRTUAL_ENV}"

echo "[WIN_TEST_VIRTUAL_ENV] Will clone test database into ${TESTDB_REPO_PARENT_DIR}"                &>> ${TEST_LOG}
echo                                                                                            &>> ${TEST_LOG}

if [ -d $TESTDB_REPO_PARENT_DIR ]
    then
        # Clear any pre-existing content
        rm -rf $TESTDB_REPO_PARENT_DIR                       &>> ${TEST_LOG}
        abort_testrun_on_error
fi
mkdir $TESTDB_REPO_PARENT_DIR                                &>> ${TEST_LOG}
abort_testrun_on_error
cd $TESTDB_REPO_PARENT_DIR                                   &>> ${TEST_LOG}
abort_testrun_on_error


echo "[WIN_TEST_VIRTUAL_ENV]  ...git clone ${WIN_TESTDB_GIT_URL} --branch ${WIN_DEPLOYABLE_GIT_BRANCH}"        &>> ${TEST_LOG}
echo "[WIN_TEST_VIRTUAL_ENV]              (current directory for git clone is $(pwd)"                         &>> ${TEST_LOG}
# Initialize Bash's `SECONDS` timer so that at the end we can compute how long this action takes
SECONDS=0
echo                                                                                            &>> ${TEST_LOG}
git clone  ${WIN_TESTDB_GIT_URL} --branch ${WIN_DEPLOYABLE_GIT_BRANCH}                   1>> ${TEST_LOG} 2>/tmp/error
abort_testrun_on_error

echo "[WIN_TEST_VIRTUAL_ENV]  ...git checkout"        &>> ${TEST_LOG}
echo "[WIN_TEST_VIRTUAL_ENV]              (current directory for git checkout is $(pwd)"                         &>> ${TEST_LOG}
echo  
cd $TESTDB_REPO_PARENT_DIR/${WIN_TESTDB_REPO_NAME}                                   &>> ${TEST_LOG}
abort_testrun_on_error                                                                                          &>> ${TEST_LOG}
git checkout                     1>> ${TEST_LOG} 2>/tmp/error

# Compute how long we took in this script
duration=$SECONDS
echo "[WIN_TEST_VIRTUAL_ENV]         Completed 'git clone' and 'git checkout' in $duration sec"             &>> ${TEST_LOG}
echo                                                                                            &>> ${TEST_LOG}


echo "[WIN_TEST_VIRTUAL_ENV] =========== Working area and Python version"                                     &>> ${TEST_LOG}
echo                                                                                &>> ${TEST_LOG}

# Need to work out the Python distribution so we can find the deployable's folder where to run the tests. 
# E.g., if Python 3.10.4 was installed and the deployable is apodeixi,
# then in Windows deployable's would have been installed in 
#
#       ${WIN_ANACONDA_DIR}/envs/${VIRTUAL_ENV}/lib/site-packages/apodeixi
#
cd ${WIN_ANACONDA_DIR}/envs/${VIRTUAL_ENV}/lib/site-packages/${WIN_DEPLOYABLE}      1>> ${TEST_LOG} 2>/tmp/error
abort_testrun_on_error
echo                                                                                &>> ${TEST_LOG}
echo "[WIN_TEST_VIRTUAL_ENV] Current directory is $(pwd)"                             &>> ${TEST_LOG}
echo &>> ${TEST_LOG}
echo "[WIN_TEST_VIRTUAL_ENV] Python version is $(conda run -n ${VIRTUAL_ENV} python --version)" &>> ${TEST_LOG}
echo "[WIN_TEST_VIRTUAL_ENV] Python path is $(conda run -n ${VIRTUAL_ENV} which python)"       &>> ${TEST_LOG}
echo &>> ${TEST_LOG}

echo "[WIN_TEST_VIRTUAL_ENV] =========== conda run -n ${VIRTUAL_ENV} python -m unittest"        &>> ${TEST_LOG}
# Initialize Bash's `SECONDS` timer so that at the end we can compute how long this action took
SECONDS=0
echo &>> ${TEST_LOG}
conda run -n ${VIRTUAL_ENV} python -m unittest                                      1>> ${TEST_LOG} 2>/tmp/error
abort_testrun_on_error
#  GOTCHA: For some bizarre reason, unittest seems to send the test results (even when passing) to the error
# stream, so if we want that in the log we need to add them to the log by hand
cat /tmp/error >> ${TEST_LOG}
# Check if tests passed. We know there is a failure if the next-to-last line is something like "FAILED (failures=1, errors=16)"
test_status=$(tail -n 5 ${TEST_LOG})
if grep -q "FAILED" <<< "$test_status"
    then
        echo "Aborting testrun because not all tests passed" 
        echo 
        echo "${test_status}"  
        echo 
        exit 1
    else
        echo "Status of test run:"  
        echo 
        echo "${test_status}"  
        echo 
fi

# Compute how long we took in this script
duration=$SECONDS
echo "[WIN_TEST_VIRTUAL_ENV]         Completed 'python -m unittest' in $duration sec" &>> ${TEST_LOG}

echo &>> ${TEST_LOG}

if [ ! -z ${WIN_REMOVE_VIRTUAL_ENVIRONMENT_WHEN_DONE} ]
    then
        echo "[WIN_TEST_VIRTUAL_ENV] Removing virtual environment..."       &>> ${TEST_LOG}
        yes "y" | conda remove -n ${VIRTUAL_ENV} --all                          &>> ${TEST_LOG}
        echo "[WIN_TEST_VIRTUAL_ENV] ...virtual environment removed"        &>> ${TEST_LOG}
        echo
fi

echo "[WIN_TEST_VIRTUAL_ENV] =========== DONE" &>> ${TEST_LOG}
