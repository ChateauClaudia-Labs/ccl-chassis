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
# Pick the first file in the distribution folder that seems to be an Apodeixi distribution for the version of interest
#
DISTRIBUTION_FOLDER=${WIN_OUTPUT_DIR}/dist/win-64
if [ ! -d ${DISTRIBUTION_FOLDER} ]
    then
        error="Distribution folder ${DISTRIBUTION_FOLDER} does not exist. Aborting"
        echo "[A6I_WIN_TEST_VIRTUAL_ENV] $error"      &>> ${TEST_LOG}
        echo $error                             
        exit 1
fi
echo "[A6I_WIN_TEST_VIRTUAL_ENV] Looking for a file apodeixi-${APODEIXI_VERSION}* in  ${DISTRIBUTION_FOLDER}" &>> ${TEST_LOG}
export APODEIXI_DISTRIBUTION=$(echo $(ls ${DISTRIBUTION_FOLDER} | grep "apodeixi-${WIN_APODEIXI_VERSION}") | awk '{print $1}') \
                1>> ${TEST_LOG} 2>/tmp/error
abort_testrun_on_error
if [ -z ${APODEIXI_DISTRIBUTION} ]
    then
        error="Could not find Apodeixi distribution. Aborting"
        echo "[A6I_WIN_TEST_VIRTUAL_ENV] $error"       &>> ${TEST_LOG}
        echo $error                             
        exit 1
fi

# NB: Redirecting with &>> appends both standard output and standard error to the file

echo "[A6I_WIN_TEST_VIRTUAL_ENV] ---------- Conda Windows install & test logs ---------- $(date) ---------- "       &>> ${TEST_LOG}
echo                                                                                                        &>> ${TEST_LOG}

echo "[A6I_WIN_TEST_VIRTUAL_ENV] Hostname=$(hostname)"                                                            &>> ${TEST_LOG}
echo                                                                                                        &>> ${TEST_LOG}
cd ${WIN_WORKING_DIR}                                                                                           &>> ${TEST_LOG}
echo "[A6I_WIN_TEST_VIRTUAL_ENV] Current directory is $(pwd)"                                                     &>> ${TEST_LOG}
echo "[A6I_WIN_TEST_VIRTUAL_ENV] Current user is is $(whoami)"                                                    &>> ${TEST_LOG}
echo "[A6I_WIN_TEST_VIRTUAL_ENV] Distribution is ${APODEIXI_DISTRIBUTION}"                                        &>> ${TEST_LOG}
echo                                                                                                        &>> ${TEST_LOG}


echo "[A6I_WIN_TEST_VIRTUAL_ENV] =========== Installing Apodeixi and its dependencies..."                         &>> ${TEST_LOG}
# Initialize Bash's `SECONDS` timer so that at the end we can compute how long this action takes
SECONDS=0
echo "[A6I_WIN_TEST_VIRTUAL_ENV]  ... creating virtual environment..."                                            &>> ${TEST_LOG}
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
echo "[A6I_WIN_TEST_VIRTUAL_ENV]  ... conda install -n ${VIRTUAL_ENV} ${APODEIXI_DISTRIBUTION}..."                 &>> ${TEST_LOG}
echo                                                                                                        &>> ${TEST_LOG}
yes " y" | conda install -n ${VIRTUAL_ENV} ${DISTRIBUTION_FOLDER}/${APODEIXI_DISTRIBUTION}           1>> ${TEST_LOG} 2>/tmp/error
abort_testrun_on_error
echo                                                                                                        &>> ${TEST_LOG}
# At this point the virtual environment if pretty empty - it only has Apodeixi, but lacks Python and lacks dependencies.
# Both will be brought in if we install python
echo "[A6I_WIN_TEST_VIRTUAL_ENV]  ... now installing Apodeixi dependencies..."                             &>> ${TEST_LOG}
echo                                                                                                        &>> ${TEST_LOG}
yes " y" | conda install -n ${VIRTUAL_ENV} python                                                           &>> ${TEST_LOG}
echo                                                                                                        &>> ${TEST_LOG}
echo                                                                                                        &>> ${TEST_LOG}
duration=$SECONDS                                                                                           &>> ${TEST_LOG}
echo "[A6I_WIN_TEST_VIRTUAL_ENV] ...${APODEIXI_DISTRIBUTION} successfully installed in container in $duration sec" &>> ${TEST_LOG}
echo                                                                                                        &>> ${TEST_LOG}


echo "[A6I_WIN_TEST_VIRTUAL_ENV] =========== Installing test database..."                                         &>> ${TEST_LOG}
echo                                                                                                        &>> ${TEST_LOG}
# GOTCHA
#       Our working folder is very nested in the file hiearchy, and if we insist on doing a git clond on that
#       working folder we will probably get "Filename too long" error messages like these:
#
#                   error: unable to create file results_data/8101/foreign_key.milestones_big_rock_version/fkey.ml_2_br.T7_cli_output          post --timestamp              _EXPECTED.txt: Filename too long
#                   fatal: unable to checkout working tree
#                   warning: Clone succeeded, but checkout failed.
#
#   So to address this, we will do git clone of the test db into a different folder
#
export GIT_CLONE_DIR="$(cd ~/tmp && pwd)/${VIRTUAL_ENV}"

echo "[A6I_WIN_TEST_VIRTUAL_ENV] Will clone test database in ${GIT_CLONE_DIR}"                &>> ${TEST_LOG}
echo                                                                                            &>> ${TEST_LOG}

if [ -d $GIT_CLONE_DIR ]
    then
        # Clear any pre-existing content
        rm -rf $GIT_CLONE_DIR                       &>> ${TEST_LOG}
        abort_testrun_on_error
fi
mkdir $GIT_CLONE_DIR                                &>> ${TEST_LOG}
abort_testrun_on_error
cd $GIT_CLONE_DIR                                   &>> ${TEST_LOG}
abort_testrun_on_error


echo "[A6I_WIN_TEST_VIRTUAL_ENV]  ...git clone ${WIN_APODEIXI_TESTDB_GIT_URL} --branch ${WIN_APODEIXI_GIT_BRANCH}"        &>> ${TEST_LOG}
echo "[A6I_WIN_TEST_VIRTUAL_ENV]              (current directory for git clone is $(pwd)"                         &>> ${TEST_LOG}
# Initialize Bash's `SECONDS` timer so that at the end we can compute how long this action takes
SECONDS=0
echo                                                                                            &>> ${TEST_LOG}
git clone  ${WIN_APODEIXI_TESTDB_GIT_URL} --branch ${WIN_APODEIXI_GIT_BRANCH}                   1>> ${TEST_LOG} 2>/tmp/error
abort_testrun_on_error

echo "[A6I_WIN_TEST_VIRTUAL_ENV]  ...git checkout"        &>> ${TEST_LOG}
echo "[A6I_WIN_TEST_VIRTUAL_ENV]              (current directory for git checkout is $(pwd)"                         &>> ${TEST_LOG}
echo  
cd $GIT_CLONE_DIR/apodeixi-testdb                                   &>> ${TEST_LOG}
abort_testrun_on_error                                                                                          &>> ${TEST_LOG}
git checkout                     1>> ${TEST_LOG} 2>/tmp/error

# Compute how long we took in this script
duration=$SECONDS
echo "[A6I_WIN_TEST_VIRTUAL_ENV]         Completed 'git clone' and 'git checkout' in $duration sec"             &>> ${TEST_LOG}
echo                                                                                            &>> ${TEST_LOG}


echo "[A6I_WIN_TEST_VIRTUAL_ENV] =========== Making a copy of Apodeixi config file suitable for Window paths"   &>> ${TEST_LOG}
echo                                                                                &>> ${TEST_LOG}

# We can't use the same apodeixi_config.toml in Windows as the one in Linux, since paths are different. So we will
# assume that the pipeline definition has a Linux-oriented apodeixi_config_toml to inject, and now we make a copy to
# the working folder and modify its paths to Windows. That will become the $INJECTED_CONFIG_DIRECTORY we end up using
# when running the tests
#
export INJECTED_CONFIG_DIRECTORY="${WIN_WORKING_DIR}/apodeixi_testdb_config"
if [ ! -d $INJECTED_CONFIG_DIRECTORY ]
    then
        mkdir $INJECTED_CONFIG_DIRECTORY
fi
# Copy Linux-oriented test config file to the working area from where Windows will take it
cp "${WIN_INJECTED_CONFIG_DIRECTORY}/apodeixi_config.toml" ${INJECTED_CONFIG_DIRECTORY}/

# We use sed to replace 'home/work' in the Apodeixi config file. Since "/" is part of the text
# being replaced, we choose a different sed delimeter (we use "#" instead of the default delimeter "/")
sed -i "s#/home/work/#${GIT_CLONE_DIR}/#g" ${INJECTED_CONFIG_DIRECTORY}/apodeixi_config.toml

#
# GOTCHA:
#       At this point, GIT_CLONE_DIR is something like
#
#               /c/Users/aleja/tmp/test_220501.144650
#
#       but we need ${INJECTED_CONFIG_DIRECTORY}/apodeixi_config.toml to have paths like 
#
#               C:/Users/aleja/tmp/test_220501.144650
#
#       to prevent problems when loading the yaml file "/c/Users/aleja/tmp/test_220501.144650/apodeixi-testdb/test_config.yaml"
#       
#       So we do another sed call, replacing "/c/" by "C:/"
#
sed -i "s#/c/#C:/#g" ${INJECTED_CONFIG_DIRECTORY}/apodeixi_config.toml

# Apodeixi's test harness expects these variables, so they must have a name as expected by Apodeixi
export APODEIXI_CONFIG_DIRECTORY="${APODEIXI_CONFIG_DIRECTORY}"

echo &>> ${TEST_LOG}

echo "[A6I_WIN_TEST_VIRTUAL_ENV] =========== Working area and Python version"                                     &>> ${TEST_LOG}
echo                                                                                &>> ${TEST_LOG}
#cd /home/work/apodeixi &>> ${TEST_LOG}

# Need to work out the Python distribution so we can find the apodeixi folder where to run the tests. 
# E.g., if Python 3.10.4 was installed, then in Windows apodeixi would have been installed in 
#
#       ${WIN_ANACONDA_DIR}/envs/${VIRTUAL_ENV}/lib/site-packages/apodeixi
#
cd ${WIN_ANACONDA_DIR}/envs/${VIRTUAL_ENV}/lib/site-packages/apodeixi      1>> ${TEST_LOG} 2>/tmp/error
abort_testrun_on_error
echo                                                                                &>> ${TEST_LOG}
echo "[A6I_WIN_TEST_VIRTUAL_ENV] Current directory is $(pwd)"                             &>> ${TEST_LOG}
echo &>> ${TEST_LOG}
echo "[A6I_WIN_TEST_VIRTUAL_ENV] Python version is $(conda run -n ${VIRTUAL_ENV} python --version)" &>> ${TEST_LOG}
echo "[A6I_WIN_TEST_VIRTUAL_ENV] Python path is $(conda run -n ${VIRTUAL_ENV} which python)"       &>> ${TEST_LOG}
echo &>> ${TEST_LOG}

echo "[A6I_WIN_TEST_VIRTUAL_ENV] =========== conda run -n ${VIRTUAL_ENV} python -m unittest"        &>> ${TEST_LOG}
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
echo "[A6I_WIN_TEST_VIRTUAL_ENV]         Completed 'python -m unittest' in $duration sec" &>> ${TEST_LOG}

echo &>> ${TEST_LOG}

if [ ! -z ${WIN_REMOVE_VIRTUAL_ENVIRONMENT_WHEN_DONE} ]
    then
        echo "[A6I_WIN_TEST_VIRTUAL_ENV] Removing virtual environment..."       &>> ${TEST_LOG}
        yes "y" | conda remove -n ${VIRTUAL_ENV} --all                          &>> ${TEST_LOG}
        echo "[A6I_WIN_TEST_VIRTUAL_ENV] ...virtual environment removed"        &>> ${TEST_LOG}
        echo
fi

echo "[A6I_WIN_TEST_VIRTUAL_ENV] =========== DONE" &>> ${TEST_LOG}
