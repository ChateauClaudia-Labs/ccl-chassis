#!/usr/bin/env bash

# This script is meant to run inside the condabuild server container.
#
# CONVENTION:
#           Environment variables that begin with "WIN_" refer to Windows paths/concepts and should have
#       been "passed" by the caller, where "passed" is accomplished by: 
#       - The caller makes a copy of this script
#       - The caller modified the copy by inserting at the top lines to set each of those "WIN_..." environment
#           variables
#       - Caller then invokes that modified copy of this script, as opposed to invoking this script.
#       All other environment variables in this script are defined within this script.
#S
LOGS_DIR="${WIN_OUTPUT_DIR}/logs" 
if [ ! -d "${LOGS_DIR}" ]; then
  mkdir ${LOGS_DIR}
fi

export CONDA_BUILD_LOG="${LOGS_DIR}/${WIN_TIMESTAMP}_windows_condabuild.txt"

abort_testrun_on_error() {
if [[ $? != 0 ]]; then
    #error=$(</tmp/error)
    echo 
    echo "${WIN_ERR_PROMPT} ${error}"                                                       &>> ${CONDA_BUILD_LOG}
    # Signal error again, this time for caller to catch, but limiting error to caller to just the last 5 lines.
    # If caller wants to see all the error message, caller can go to the logs
    echo "Aborting testrun. Here is the error message (cut down to last 5 lines):"
    echo 
    tail -n 5 /tmp/error
    echo 
    #  Before exiting, make sure we save the full errors to the test log, so we can debug later
    cat /tmp/error >> ${CONDA_BUILD_LOG}
    exit 1
fi    
}

# Want to find do initial conda installs with a base environment conda like:
#
#         /c/Users/aleja/Documents/CodeImages/Technos/Anaconda3/Scripts/conda
#
# However, when we actually buid, we want to use a virtual environment's conda-build so that distribution built is not
# "polluting" the host.
# In saying this, we mean "polluting" = modifying host's base Anaconda environment by e.g., overwriting the base
# environment's area for conda-build output, such as overwriting
#
#   C:\Users\aleja\Documents\CodeImages\Technos\Anaconda3\conda-bld\win-64\apodeixi-0.9.9-py310_0.tar.bz2
#
# each time we run this pipeline. So want conda-build to come instead from an environment area, like
#
#   /c/Users/aleja/Documents/CodeImages/Technos/Anaconda3/envs/scratch2/Scripts/conda-build
#
export BASE_CONDA_EXE=${WIN_ANACONDA_DIR}/Scripts/conda
export VIRTUAL_ENV="condabuild_${WIN_TIMESTAMP}"
export VIRTUAL_ENV_CONDA_BLD_EXE=${WIN_ANACONDA_DIR}/envs/${VIRTUAL_ENV}/Scripts/conda-build

echo "[A6I_WIN_BLD_VIRTUAL_ENV] ---------- Windows conda build logs ---------- $(date) ---------- " &>> ${CONDA_BUILD_LOG}

echo "[A6I_WIN_BLD_VIRTUAL_ENV] Hostname=$(hostname)"                                 &>> ${CONDA_BUILD_LOG}
echo                                                                                  &>> ${CONDA_BUILD_LOG}

echo "[A6I_WIN_BLD_VIRTUAL_ENV] Current directory is $(pwd)"                          &>> ${CONDA_BUILD_LOG}
echo "[A6I_WIN_BLD_VIRTUAL_ENV] Current user is $(whoami)"                            &>> ${CONDA_BUILD_LOG}

echo                                                                                  &>> ${CONDA_BUILD_LOG}

echo "[A6I_WIN_BLD_VIRTUAL_ENV] =========== conda-build  ${WIN_CONDA_RECIPE}"     &>> ${CONDA_BUILD_LOG}
# Initialize Bash's `SECONDS` timer so that at the end we can compute how long this action took
SECONDS=0
echo                                                                                  &>> ${CONDA_BUILD_LOG}
echo "[A6I_WIN_TEST_VIRTUAL_ENV]  ... creating virtual environment..."                &>> ${CONDA_BUILD_LOG}  
echo                                                                                  &>> ${CONDA_BUILD_LOG}
# Conda virtual environment for installation and test
yes "y" | ${BASE_CONDA_EXE} create -n ${VIRTUAL_ENV}                                  1>> ${CONDA_BUILD_LOG} 2>/tmp/error
abort_testrun_on_error
echo "[A6I_WIN_BLD_VIRTUAL_ENV] Virtual environment is ${VIRTUAL_ENV}"                &>> ${CONDA_BUILD_LOG}
echo                                                                                  &>> ${CONDA_BUILD_LOG}
# Get our local conda-build so that distribution built is not put in the base environment's area
yes "y" | ${BASE_CONDA_EXE} install -n ${VIRTUAL_ENV} conda-build                     &>> ${CONDA_BUILD_LOG}

echo "[A6I_WIN_BLD_VIRTUAL_ENV] Build executable is ${VIRTUAL_ENV_CONDA_BLD_EXE}"     &>> ${CONDA_BUILD_LOG}
echo                                                                                  &>> ${CONDA_BUILD_LOG}
echo "[A6I_WIN_BLD_VIRTUAL_ENV] Build recipe is ${WIN_CONDA_RECIPE}"                  &>> ${CONDA_BUILD_LOG}
echo                                                                                  &>> ${CONDA_BUILD_LOG}
${VIRTUAL_ENV_CONDA_BLD_EXE} ${WIN_CONDA_RECIPE_DIR}/${WIN_CONDA_RECIPE}              &>> ${CONDA_BUILD_LOG}
if [[ $? != 0 ]]; then
    error=$(</tmp/error)
    echo "${ERR_PROMPT} ${error}" &>> ${CONDA_BUILD_LOG}
    # Signal error again, this time for caller to catch
    echo "Aborting build because: ${error}" 
    exit 1
fi
# Compute how long we took in this script
duration=$SECONDS
echo                                                                                  &>> ${CONDA_BUILD_LOG}
echo "[A6I_WIN_BLD_VIRTUAL_ENV]         Completed 'conda-build' in $duration sec"     &>> ${CONDA_BUILD_LOG}

echo                                                                                  &>> ${CONDA_BUILD_LOG}

if [ ! -d ${WIN_OUTPUT_DIR}/dist ]
    then
        mkdir ${WIN_OUTPUT_DIR}/dist
fi


# Move the linux-64 to this container's external volume for output
cp -r ${WIN_ANACONDA_DIR}/envs/${VIRTUAL_ENV}/conda-bld/win-64 ${WIN_OUTPUT_DIR}/dist/  &>> ${CONDA_BUILD_LOG}

echo                                                                                    &>> ${CONDA_BUILD_LOG}
echo "[A6I_WIN_BLD_VIRTUAL_ENV] Created these distributions:"                           &>> ${CONDA_BUILD_LOG}
echo                                                                                    &>> ${CONDA_BUILD_LOG}
echo "$(ls ${WIN_OUTPUT_DIR}/dist)"                                                     &>> ${CONDA_BUILD_LOG}
echo                                                                                    &>> ${CONDA_BUILD_LOG}

if [ ! -z ${WIN_REMOVE_VIRTUAL_ENVIRONMENT_WHEN_DONE} ]
    then
        echo "[A6I_WIN_TEST_VIRTUAL_ENV] Removing virtual environment..."               &>> ${CONDA_BUILD_LOG}
        yes "y" | ${BASE_CONDA_EXE} remove -n ${VIRTUAL_ENV} --all                      &>> ${CONDA_BUILD_LOG}
        echo "[A6I_WIN_TEST_VIRTUAL_ENV] ...virtual environment removed"                &>> ${CONDA_BUILD_LOG}
        echo
fi
echo "[A6I_WIN_BLD_VIRTUAL_ENV] =========== DONE"                                        &>> ${CONDA_BUILD_LOG}
