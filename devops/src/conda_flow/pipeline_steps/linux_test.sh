#!/usr/bin/env bash

# This script is meant to run inside the build server container.
#
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
    echo "${ERR_PROMPT} ${error}"                                                                           &>> ${TEST_LOG}
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

export TEST_LOG="${LOGS_DIR}/${TIMESTAMP}_linux_test.txt"
export PATH=/home/anaconda3/bin:$PATH      
# Pick the first file in the distribution folder that seems to be an Apodeixi distribution for the version of interest
#
#  a=$(echo $(ls | grep "2021.11") | awk '{print $1}')
DISTRIBUTION_FOLDER=/home/output/dist/linux-64
if [ ! -d ${DISTRIBUTION_FOLDER} ]
    then
        error="Distribution folder ${DISTRIBUTION_FOLDER} does not exist. Aborting"
        echo "[A6I_TEST_CONTAINER] $error"      &>> ${TEST_LOG}
        echo $error                             >/dev/stderr
        exit 1
fi
echo "[A6I_TEST_CONTAINER] Looking for a file apodeixi-${APODEIXI_VERSION}* in  ${DISTRIBUTION_FOLDER}" &>> ${TEST_LOG}
export APODEIXI_DISTRIBUTION=$(echo $(ls ${DISTRIBUTION_FOLDER} | grep "apodeixi-${APODEIXI_VERSION}") | awk '{print $1}') \
                1>> ${TEST_LOG} 2>/tmp/error
abort_testrun_on_error
if [ -z ${APODEIXI_DISTRIBUTION} ]
    then
        error="Could not find Apodeixi distribution. Aborting"
        echo "[A6I_TEST_CONTAINER] $error"       &>> ${TEST_LOG}
        echo $error                             >/dev/stderr
        exit 1
fi

# NB: Redirecting with &>> appends both standard output and standard error to the file

echo "[A6I_TEST_CONTAINER] ---------- Conda Linux install & test logs ---------- $(date) ---------- "       &>> ${TEST_LOG}
echo                                                                                                        &>> ${TEST_LOG}

echo "[A6I_TEST_CONTAINER] Hostname=$(hostname)"                                                            &>> ${TEST_LOG}
echo                                                                                                        &>> ${TEST_LOG}
cd ${WORKING_DIR}                                                                                           &>> ${TEST_LOG}
echo "[A6I_TEST_CONTAINER] Current directory is $(pwd)"                                                     &>> ${TEST_LOG}
echo "[A6I_TEST_CONTAINER] Current user is is $(whoami)"                                                    &>> ${TEST_LOG}
echo "[A6I_TEST_CONTAINER] Distribution is ${APODEIXI_DISTRIBUTION}"                                        &>> ${TEST_LOG}
echo                                                                                                        &>> ${TEST_LOG}


echo "[A6I_TEST_CONTAINER] =========== Installing Apodeixi and its dependencies..."                         &>> ${TEST_LOG}
# Initialize Bash's `SECONDS` timer so that at the end we can compute how long this action takes
SECONDS=0
echo "[A6I_TEST_CONTAINER]  ... creating virtual environment..."                                            &>> ${TEST_LOG}                                                                 &>> ${TEST_LOG}
echo                                                                                                        &>> ${TEST_LOG}
conda update -n base -c defaults conda                                                          1>> ${TEST_LOG} 2>/tmp/error
abort_testrun_on_error
echo                                                                                                        &>> ${TEST_LOG}
# Conda virtual environment for installation and test
yes "y" | conda create -n test-apo-bld                                                          1>> ${TEST_LOG} 2>/tmp/error
abort_testrun_on_error


### GOTCHA
#           It is virtually impossible to initialize conda in a container.
#           That's because the 'conda init' presumes a login shell
#       Workaround, is to always 'conda <command> -n <environment>' for all conda commands, instead
#       of doing 'conda activate <env>'

echo                                                                                                        &>> ${TEST_LOG}
echo "[A6I_TEST_CONTAINER]  ... conda install -n test-apo-bld ${APODEIXI_DISTRIBUTION}..."                 &>> ${TEST_LOG}
echo                                                                                                        &>> ${TEST_LOG}
conda install -n test-apo-bld ${DISTRIBUTION_FOLDER}/${APODEIXI_DISTRIBUTION}                        1>> ${TEST_LOG} 2>/tmp/error
abort_testrun_on_error
echo                                                                                                        &>> ${TEST_LOG}
# At this point the virtual environment if pretty empty - it only has Apodeixi, but lacks Python and lacks dependencies.
# Both will be brought in if we install python
echo "[A6I_TEST_CONTAINER]  ... now installing Apodeixi dependencies..."                                    &>> ${TEST_LOG}
echo                                                                                                        &>> ${TEST_LOG}
yes " y" | conda install -n test-apo-bld python                                                                             &>> ${TEST_LOG}
echo                                                                                                        &>> ${TEST_LOG}
echo                                                                                                        &>> ${TEST_LOG}
duration=$SECONDS                                                                                           &>> ${TEST_LOG}
echo "[A6I_TEST_CONTAINER] ...${APODEIXI_DISTRIBUTION} successfully installed in container in $duration sec" &>> ${TEST_LOG}
echo                                                                                                        &>> ${TEST_LOG}


echo "[A6I_TEST_CONTAINER] =========== Installing test database..."                                         &>> ${TEST_LOG}
echo                                                                                                        &>> ${TEST_LOG}
echo "[A6I_TEST_CONTAINER]  ...git clone ${APODEIXI_TESTDB_GIT_URL} --branch ${APODEIXI_GIT_BRANCH}"        &>> ${TEST_LOG}
echo "[A6I_TEST_CONTAINER]              (current directory for git clone is $(pwd)"                         &>> ${TEST_LOG}
# Initialize Bash's `SECONDS` timer so that at the end we can compute how long this action takes
SECONDS=0
echo                                                                                            &>> ${TEST_LOG}
git clone  ${APODEIXI_TESTDB_GIT_URL} --branch ${APODEIXI_GIT_BRANCH}                           1>> ${TEST_LOG} 2>/tmp/error
abort_testrun_on_error

# Compute how long we took in this script
duration=$SECONDS
echo "[A6I_TEST_CONTAINER]         Completed 'git clone' in $duration sec"                                  &>> ${TEST_LOG}


echo &>> ${TEST_LOG}

echo "[A6I_TEST_CONTAINER] =========== Working area and Python version"                                     &>> ${TEST_LOG}
echo &>> ${TEST_LOG}
#cd /home/work/apodeixi &>> ${TEST_LOG}

# Need to work out the Python distribution so we can find the apodeixi folder where to run the tests. 
# E.g., if Python 3.10.4 was installed, then apodeixi would have been installed in 
#
#       /home/anaconda3/envs/test-apo-bld/lib/python3.10/site-packages/apodeixi
#
# So to construct the folder name "python3.10", we do these things:
#
#   - Call 'python --version'. In our example, that would give "Python 3.10.4". Though:
#       => we actually call 'conda run -n test-apo-bld python --version'
#       => that's so that we get the version of python *IN THE ENVIRONMENT WE USE*, not the base environment
#       => Otherwise may bet the base environment's "Python 3.9.7" instead of our environment's "Python 3.10.4"
#   - Pipe that to awk, getting the 2nd token: "3.10.4", and save it to a variable
#   - Then pipe that result ("3.10.4") through awk twice, with a "." delimeter, getting $1, $2 respectively into
#     variables for major and minor versions
#   - Lastly, we assemble the python distribution folder: "python3.10", whice allows us to change directory to apodeixi
#
full_version=$(conda run -n test-apo-bld python --version | awk '{print $2}')       &>> ${TEST_LOG}
major_version=$(echo $full_version | awk -F. '{print $1}')                          &>> ${TEST_LOG}
minor_version=$(echo $full_version | awk -F. '{print $2}')                          &>> ${TEST_LOG}
python_dist="python${major_version}.${minor_version}"                               &>> ${TEST_LOG}

cd /home/anaconda3/envs/test-apo-bld/lib/${python_dist}/site-packages/apodeixi      1>> ${TEST_LOG} 2>/tmp/error
abort_testrun_on_error
echo                                                                                &>> ${TEST_LOG}
echo "[A6I_TEST_CONTAINER] Current directory is $(pwd)"                             &>> ${TEST_LOG}
echo &>> ${TEST_LOG}
echo "[A6I_TEST_CONTAINER] Python version is $(conda run -n test-apo-bld python --version)" &>> ${TEST_LOG}
echo "[A6I_TEST_CONTAINER] Python path is $(conda run -n test-apo-bld which python)"       &>> ${TEST_LOG}
echo &>> ${TEST_LOG}

echo "[A6I_TEST_CONTAINER] =========== conda run -n test-apo-bld python -m unittest"        &>> ${TEST_LOG}
# Initialize Bash's `SECONDS` timer so that at the end we can compute how long this action took
SECONDS=0
echo &>> ${TEST_LOG}
conda run -n test-apo-bld python -m unittest                                      1>> ${TEST_LOG} 2>/tmp/error
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
