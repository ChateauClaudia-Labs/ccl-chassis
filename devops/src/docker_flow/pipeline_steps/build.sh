#!/usr/bin/env bash

# This script is meant to run inside the build server container.
#

# NB: /home/output is mounted on this container's host filesystem
#
LOGS_DIR="/home/output/logs" # This is a mount of a directory in host machine, so it might already exist
if [ ! -d "${LOGS_DIR}" ]; then
  mkdir ${LOGS_DIR}
fi

WORKING_DIR="/home/work"
mkdir ${WORKING_DIR}

export BUILD_LOG="${LOGS_DIR}/${TIMESTAMP}_build.txt"

# NB: Redirecting with &>> appends both standard output and standard error to the file

echo "[A6I_BUILD_SERVER] ---------- Build logs ---------- $(date) ---------- " &>> ${BUILD_LOG}
echo  &>> ${BUILD_LOG}

echo "[A6I_BUILD_SERVER] Hostname=$(hostname)" &>> ${BUILD_LOG}
echo &>> ${BUILD_LOG}
cd ${WORKING_DIR} &>> ${BUILD_LOG}
echo "[A6I_BUILD_SERVER] Current directory is $(pwd)" &>> ${BUILD_LOG}
echo "[A6I_BUILD_SERVER] Current user is is $(whoami)" &>> ${BUILD_LOG}
echo &>> ${BUILD_LOG}

echo "[A6I_BUILD_SERVER] =========== git clone  ${APODEIXI_GIT_URL} --branch ${APODEIXI_GIT_BRANCH}" &>> ${BUILD_LOG}
# Initialize Bash's `SECONDS` timer so that at the end we can compute how long this action took
SECONDS=0
echo &>> ${BUILD_LOG}
git clone  ${APODEIXI_GIT_URL} --branch ${APODEIXI_GIT_BRANCH} 1>> ${BUILD_LOG} 2>/tmp/error
if [[ $? != 0 ]]; then
    error=$(</tmp/error)
    echo "${ERR_PROMPT} ${error}" &>> ${BUILD_LOG}
    # Signal error again, this time for caller to catch
    echo "Aborting build because: ${error}"  >/dev/stderr
    exit 1
fi
# Compute how long we took in this script
duration=$SECONDS
echo "[A6I_BUILD_SERVER]         Completed 'git clone' in $duration sec" &>> ${BUILD_LOG}


echo &>> ${BUILD_LOG}

echo "[A6I_BUILD_SERVER] =========== Working area and Python version" &>> ${BUILD_LOG}
echo &>> ${BUILD_LOG}
cd /home/work/apodeixi &>> ${BUILD_LOG}
echo "[A6I_BUILD_SERVER] Current directory is $(pwd)" &>> ${BUILD_LOG}
echo &>> ${BUILD_LOG}
echo "[A6I_BUILD_SERVER] Python version is $(python --version)" &>> ${BUILD_LOG}
echo "[A6I_BUILD_SERVER] Python path is $(which python)" &>> ${BUILD_LOG}
echo &>> ${BUILD_LOG}

#cd ${WORKING_DIR}/repo &>> ${BUILD_LOG}
#echo "[A6I_BUILD_SERVER] Changing directory to $(pwd)" &>> ${BUILD_LOG}
echo &>> ${BUILD_LOG}
echo "[A6I_BUILD_SERVER] =========== python setup.py bdist_wheel" &>> ${BUILD_LOG}
# Initialize Bash's `SECONDS` timer so that at the end we can compute how long this action took
SECONDS=0
echo &>> ${BUILD_LOG}
python setup.py bdist_wheel &>> ${BUILD_LOG} 2>/tmp/error
if [[ $? != 0 ]]; then
    error=$(</tmp/error)
    echo "${ERR_PROMPT} ${error}" &>> ${BUILD_LOG}
    # Signal error again, this time for caller to catch
    echo "Aborting build because: ${error}"  >/dev/stderr
    exit 1
fi
# Compute how long we took in this script
duration=$SECONDS
echo "[A6I_BUILD_SERVER]         Completed 'python setup.py' in $duration sec" &>> ${BUILD_LOG}

echo &>> ${BUILD_LOG}

echo "[A6I_BUILD_SERVER] =========== copy wheel to host" &>> ${BUILD_LOG}
echo &>> ${BUILD_LOG}
cp -r dist /home/output/ &>> ${BUILD_LOG} 2>/tmp/error
if [[ $? != 0 ]]; then
    error=$(</tmp/error)
    echo "${ERR_PROMPT} ${error}" &>> ${BUILD_LOG}
    # Signal error again, this time for caller to catch
    echo "Aborting build because: ${error}"  >/dev/stderr
    exit 1
fi

echo "[A6I_BUILD_SERVER] Copied $(ls /home/output/dist)" &>> ${BUILD_LOG}
echo &>> ${BUILD_LOG}
echo "[A6I_BUILD_SERVER] =========== DONE" &>> ${BUILD_LOG}
