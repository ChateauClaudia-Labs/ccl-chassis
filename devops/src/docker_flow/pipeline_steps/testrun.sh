#!/usr/bin/env bash

# This script is meant to run inside the build server container.
#

# NB: /home/output is mounted on this container's host filesystem
#
LOGS_DIR="/home/output/logs" # This is a mount of a directory in host machine, so it might already exist
if [ ! -d "${LOGS_DIR}" ]; then
  mkdir ${LOGS_DIR}
fi

abort_testrun_on_error() {
if [[ $? != 0 ]]; then
    #error=$(</tmp/error)
    echo >/dev/stderr
    echo "${_SVC__ERR_PROMPT} ${error}" &>> ${TEST_LOG}
    # Signal error again, this time for caller to catch, but limiting error to caller to just the last 5 lines.
    # If caller wants to see all the error message, caller can go to the logs
    echo "Aborting testrun. Here is the error message (cut down to last 5 lines):"  >/dev/stderr
    echo >/dev/stderr
    tail -n 5 /tmp/error >/dev/stderr
    echo >/dev/stderr 
    #  Before exiting, make sure we save the full errors to the test log, so we can debug later
    cat /tmp/error >> ${TEST_LOG}
    exit 1
fi    
}

WORKING_DIR="/home/work"
if [ ! -d "${WORKING_DIR}" ]; then
    mkdir ${WORKING_DIR}
fi

export TEST_LOG="${LOGS_DIR}/${TIMESTAMP}_testrun.txt"

# NB: Redirecting with &>> appends both standard output and standard error to the file

echo "[A6I_TEST_CONTAINER] ---------- Test logs ---------- $(date) ---------- " &>> ${TEST_LOG}
echo                                                        &>> ${TEST_LOG}

echo "[A6I_TEST_CONTAINER] Hostname=$(hostname)"            &>> ${TEST_LOG}
echo                                                        &>> ${TEST_LOG}
cd ${WORKING_DIR}                                           &>> ${TEST_LOG}
echo "[A6I_TEST_CONTAINER] Current directory is $(pwd)"     &>> ${TEST_LOG}
echo "[A6I_TEST_CONTAINER] Current user is is $(whoami)"    &>> ${TEST_LOG}
echo                                                        &>> ${TEST_LOG}

echo "[A6I_TEST_CONTAINER] =========== git clone ${_CFG__TESTDB_GIT_URL} --branch ${_CFG__DEPLOYABLE_GIT_BRANCH}" &>> ${TEST_LOG}
echo "[A6I_TEST_CONTAINER]              (current directory for git clone is $(pwd)"                     &>> ${TEST_LOG}
# Initialize Bash's `SECONDS` timer so that at the end we can compute how long this action took
SECONDS=0
echo &>> ${TEST_LOG}
git clone  ${_CFG__TESTDB_GIT_URL} --branch ${_CFG__DEPLOYABLE_GIT_BRANCH} 1>> ${TEST_LOG} 2>/tmp/error
abort_testrun_on_error

# Compute how long we took in this script
duration=$SECONDS
echo "[A6I_TEST_CONTAINER]         Completed 'git clone' in $duration sec" &>> ${TEST_LOG}


echo &>> ${TEST_LOG}

echo "[A6I_TEST_CONTAINER] =========== Working area and Python version" &>> ${TEST_LOG}
echo &>> ${TEST_LOG}

cd /usr/local/lib/${_CFG__UBUNTU_PYTHON_PACKAGE}/dist-packages/${_CFG__DEPLOYABLE} &>> ${TEST_LOG}

echo "[A6I_TEST_CONTAINER] Current directory is $(pwd)" &>> ${TEST_LOG}
echo &>> ${TEST_LOG}
echo "[A6I_TEST_CONTAINER] Python version is $(python --version)" &>> ${TEST_LOG}
echo "[A6I_TEST_CONTAINER] Python path is $(which python)" &>> ${TEST_LOG}
echo &>> ${TEST_LOG}

echo "[A6I_TEST_CONTAINER] =========== python -m unittest" &>> ${TEST_LOG}
# Initialize Bash's `SECONDS` timer so that at the end we can compute how long this action took
SECONDS=0
echo &>> ${TEST_LOG}
python -m unittest 1>> ${TEST_LOG} 2>/tmp/error
abort_testrun_on_error
#  GOTCHA: For some bizarre reason, unittest seems to send the test results (even when passing) to the error
# stream, so if we want that in the log we need to add them to the log by hand
cat /tmp/error >> ${TEST_LOG}
# Check if tests passed. We know there is a failure if the next-to-last line is something like "FAILED (failures=1, errors=16)"
test_status=$(tail -n 5 ${TEST_LOG})
if grep -q "FAILED" <<< "$test_status"
    then
        echo "Aborting testrun because not all tests passed"  >/dev/stderr
        echo >/dev/stderr
        echo "${test_status}"  >/dev/stderr
        echo >/dev/stderr
        exit 1
    else
        echo "Status of test run:"  >/dev/stdout
        echo >/dev/stdout
        echo "${test_status}"  >/dev/stdout
        echo >/dev/stdout
fi

# Compute how long we took in this script
duration=$SECONDS
echo "[A6I_TEST_CONTAINER]         Completed 'python -m unittest' in $duration sec" &>> ${TEST_LOG}

echo &>> ${TEST_LOG}

echo "[A6I_TEST_CONTAINER] =========== DONE" &>> ${TEST_LOG}
