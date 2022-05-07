#!/usr/bin/env bash

# This script is meant to run inside the condabuild server container.
#

# NB: /home/output is mounted on this container's host filesystem
#

LOGS_DIR="/home/output/logs" # This is a mount of a directory in host machine, so it might already exist
if [ ! -d "${LOGS_DIR}" ]; then
  mkdir ${LOGS_DIR}
fi

export CONDA_BUILD_LOG="${LOGS_DIR}/${TIMESTAMP}_linux_condabuild.txt"

echo "[A6I_CONDA_BUILD_SERVER] ---------- Conda build logs ---------- $(date) ---------- " &>> ${CONDA_BUILD_LOG}

echo "[A6I_CONDA_BUILD_SERVER] Hostname=$(hostname)" &>> ${CONDA_BUILD_LOG}
echo &>> ${CONDA_BUILD_LOG}

echo "[A6I_CONDA_BUILD_SERVER] Current directory is $(pwd)" &>> ${CONDA_BUILD_LOG}
echo "[A6I_CONDA_BUILD_SERVER] Current user is $(whoami)" &>> ${CONDA_BUILD_LOG}
echo &>> ${CONDA_BUILD_LOG}

echo "[A6I_CONDA_BUILD_SERVER] =========== conda-build  ${HOST_CONDA_RECIPE_DIR}" &>> ${CONDA_BUILD_LOG}
# Initialize Bash's `SECONDS` timer so that at the end we can compute how long this action took
SECONDS=0
echo &>> ${CONDA_BUILD_LOG}

/home/anaconda3/bin/conda-build /home/conda_build_recipe            &>> ${CONDA_BUILD_LOG}
if [[ $? != 0 ]]; then
    error=$(</tmp/error)
    echo "${ERR_PROMPT} ${error}" &>> ${CONDA_BUILD_LOG}
    # Signal error again, this time for caller to catch
    echo "Aborting build because: ${error}"  >/dev/stderr
    exit 1
fi
# Compute how long we took in this script
duration=$SECONDS
echo &>> ${CONDA_BUILD_LOG}
echo "[A6I_CONDA_BUILD_SERVER]         Completed 'conda-build' in $duration sec" &>> ${CONDA_BUILD_LOG}

echo &>> ${CONDA_BUILD_LOG}
echo "[A6I_CONDA_BUILD_SERVER] =========== Convert to all platforms and creating distribution folder" &>> ${CONDA_BUILD_LOG}
echo &>> ${CONDA_BUILD_LOG}

if [ ! -d /home/output/dist ]
    then
        mkdir /home/output/dist
fi

# GOTCHA
#   We no longer convert to other platforms because we found that 'conda covert' is buggy. 
#
#   Specifically:
#       If we convert a linux-64 build to win-64, and get, say, apodeixi-0.9.9-py310_0.tar.bz2, this
#       is corrupted as can ge seen in two ways:
#
#       First, if one attempts to install it with 'conda install podeixi-0.9.9-py310_0.tar.bz2', numerous errors like
#       these get generated:
#                CondaVerificationError: The package for apodeixi located at C:\Users\aleja\Documents\CodeImages\Technos\Anaconda3\pkgs\apodeixi-0.9.9-py310_0
#                appears to be corrupted. The path 'Lib/0/site-packages/apodeixi-0.9.9-py3.10.egg-info/PKG-INFO'
#                specified in the package manifest cannot be found.
#
#       On inspection (and this is the second way of seeing the problem), if one extracts the win-64 distribution's contents
#       doing
#               tar -xf apodeixi-0.9.9-py310_0.tar.bz2
#
#       then if one looks at the extracted file info/paths.json, one sees that the paths are corrupted because of
#       an extra "0". For example, the info/paths.json would have a line like
#
#               "_path": "Lib/0/site-packages/apodeixi-0.9.9-py3.10.egg-info/PKG-INFO"
#
#       whereas a non-corrupted distribution would have a line like
#
#               "_path": "Lib/site-packages/apodeixi-0.9.9-py3.10.egg-info/PKG-INFO"
#
#       UPSHOT: to get a win-64 distribution one must build it in Windows, not convert a Linux distribution
#
#/home/anaconda3/bin/conda convert --platform all \
#    /home/anaconda3/conda-bld/linux-64/apodeixi-${APODEIXI_VERSION}-py*.tar.bz2 \
#    -o /home/output/dist        &>> ${CONDA_BUILD_LOG}
#if [[ $? != 0 ]]; then
#    error=$(</tmp/error)
#    echo "${ERR_PROMPT} ${error}" &>> ${CONDA_BUILD_LOG}
#    # Signal error again, this time for caller to catch
#    echo "Aborting build because: ${error}"  >/dev/stderr
#    exit 1
#fi

# Move the linux-64 to this container's external volume for output
cp -r /home/anaconda3/conda-bld/linux-64 /home/output/dist/

echo &>> ${CONDA_BUILD_LOG}
echo "[A6I_CONDA_BUILD_SERVER] Created these distributions:" &>> ${CONDA_BUILD_LOG}
echo &>> ${CONDA_BUILD_LOG}
echo "$(ls /home/output/dist)" &>> ${CONDA_BUILD_LOG}
echo &>> ${CONDA_BUILD_LOG}
echo "[A6I_CONDA_BUILD_SERVER] =========== DONE" &>> ${CONDA_BUILD_LOG}
