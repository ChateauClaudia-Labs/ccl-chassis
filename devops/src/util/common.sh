#!/usr/bin/env bash

# This script has some common settings and logic applicable to all pipeline steps.
# It is expected to be sourced by each pipeline step's request script. 
# It requires that:
#       1. ${_CFG__PIPELINE_ALBUM} be set up prior to sourcing this script.

# Used to "catch exceptions", kind of, in the Bash programming environment.
# Requirements:
#   - Beforehand the error stream has been re-directored to /tmp/error (doing "2>/tmp/error" at the end of the previous command)
#
abort_on_error() {
    if [[ $? != 0 ]]; then
      error=$(</tmp/error)
      echo
      echo "${_SVC__ERR_PROMPT} ${error}"
      echo
      echo "${_SVC__ERR_PROMPT} For more detail on error, check logs under ${PIPELINE_STEP_OUTPUT}"
      exit 1
    fi
}

unblock_bats() {
    if [ ! -z ${RUNNING_BATS} ]
        then
            echo "${_SVC__INFO_PROMPT} ...stopping test container..."
            echo "${_SVC__INFO_PROMPT} ...stopped test container $(docker stop ${CONTAINER_FOR_DEPLOYABLE})"
            echo "${_SVC__INFO_PROMPT} ...removed test container $(docker rm ${CONTAINER_FOR_DEPLOYABLE})"
            echo
    fi    
}

unblock_bats_in_build() {
    if [ ! -z ${RUNNING_BATS} ]
        then
            echo "${_SVC__INFO_PROMPT} ...stopping build container..."
            echo "${_SVC__INFO_PROMPT} ...stopped build container $(docker stop ${BUILD_CONTAINER})"
            echo "${_SVC__INFO_PROMPT} ...removed build container $(docker rm ${BUILD_CONTAINER})"
            echo
    fi    
}

# Unique timestamp used e.g., as a prefix in the names of log files
# For example, "220331.120319" is a run done at 12:03 pm (and 19 seconds) on March 31, 2022
export TIMESTAMP="$(date +"%y%m%d.%H%M%S")"

export _SVC__ERR_PROMPT="[CI/CD ERROR]"
export _SVC__INFO_PROMPT="[CI/CD INFO]"

# Check that the pipeline id was passed as argument $1
if [ -z "$1" ]
  then
    echo "${_SVC__ERR_PROMPT} Pipeline id was not provided as an argument. It should be an integer id like '1001'"
    exit 1
fi
export PIPELINE_NAME="$1_pipeline" # For example, '1001_pipeline'. This is a folder with parameters defining a particular pipeline   

# We require that a pipeline "album" has been injected. A pipeline "album"
# is simply a folder with subfolders called <ID>_pipeline, where <ID> identifies a pipeline in the "album".
# Teach <ID>_pipeline folder contains subfolder for runs on the pipeline (logs, output, ...) and also contains a file
# defining the pipeline ('pipeline_definition.sh'). This definition is interpreted by CCL Chassis' DevOps' code to run the 
# the generic pipeline steps but as configured specifically for the pipeline idenfified by <ID>
#
# So we require that the caller has set the variable ${_CFG__PIPELINE_ALBUM}, we use that; else we default it
#
if [ -z "${_CFG__PIPELINE_ALBUM}" ]
    then
        echo "${ERROR_PROMPT} Command can't be processed because environment variable '_CFG__PIPELINE_ALBUM' is not set"
        exit 1
fi

# Normally the identifier for a run is the timestamp, but there is a GOTCHA:
#   - We want the same run identifier across all the pipeline steps
#   - And each pipeline step includes this file, hence each pipeline step uses a different value for $TIMESTAMP
#   - For steps, that is OK since that way the logs of different steps are sorted by time when the step ran
#   - But for the run as a whole, we need a common ID across all steps of the run
#   - Hence we take the approach of using a dedicated environment variable for the run id, separate from the
#     timestamp environment variable, and we only set it once the first time that this script is called. 
#   - We also print the header for the run only if we are setting the run id, since we don't want to print it once
#     for the run of the pipeline, not per step in the run
if [ -z "$RUN_TIMESTAMP" ]
  then
    export RUN_TIMESTAMP=${TIMESTAMP}
fi
echo "${_SVC__INFO_PROMPT} Running pipeline '${PIPELINE_NAME}' with run ID '${RUN_TIMESTAMP}'"
echo

# Check pipeline album contains a pipeline with the given ID
  [ ! -d "${_CFG__PIPELINE_ALBUM}/${PIPELINE_NAME}" ] && echo \
  && echo "${_SVC__ERR_PROMPT} '${_CFG__PIPELINE_ALBUM}/${PIPELINE_NAME}' does not exist" \
  && echo \
  && exit 1

# The _CFG__PIPELINE_HISTORY is the root folder where pipeline runs store all their output, logs, etc.,
# organized in subfolders per pipeline name, then by run for each pipeline.
#
#   If it is not set, we will assume that output shoud be saved in the album definition itself.
if [ -z "${_CFG__PIPELINE_HISTORY}" ]
    then
        export _CFG__PIPELINE_HISTORY=${_CFG__PIPELINE_ALBUM}/../apdo_builds
fi

# Used for writing all output produced by a pipeline run. 
# In particular, it is passed as an external volume to containers used by the pipeline to e.g. build.
# This could be injected if the environment variable was previously set (for example, test cases may want to
# inject it to be a sub-area of test output's area), but if it has not been injected, we default it.
if [ -z "${PIPELINE_STEP_OUTPUT}" ]
    then
        export PIPELINE_STEP_OUTPUT=${_CFG__PIPELINE_HISTORY}/${PIPELINE_NAME}/output/${RUN_TIMESTAMP}_pipeline_run
        if [ ! -d "${_CFG__PIPELINE_HISTORY}/${PIPELINE_NAME}/output" ]
            then
                mkdir -p "${_CFG__PIPELINE_HISTORY}/${PIPELINE_NAME}/output"
        fi
fi

# Create output folder if it does not already exist
if [ ! -d "${PIPELINE_STEP_OUTPUT}" ]
    then
        mkdir -p "${PIPELINE_STEP_OUTPUT}"
fi


# ${PIPELINE_STEP_INTAKE} is the folder from which pipeline steps intake data created in upstream pipeline steps.
#
# It normally is the same as ${PIPELINE_STEP_OUTPUT}, but in some use cases they are different
# (for example, when testing a particular pipeline step while using a stub for the upstream computed data
# that it may need)
#
# As an added twist, when the operator is "continuing" a pipeline from a previous point, then the user can
# pass it as an argument to $2. I.e., $2 points to the previous pipeline run's output, and this new run will
# get its intake from there. Obviously this makes sense only if the caller is not re-running steps that had completed
# in the previous run, but is instead running only subsequent steps.
#
if [ ! -z $2 ] # If the intake folder is passed by hand, supersede defaults and programmatic injections
    then
        export PIPELINE_STEP_INTAKE=${2}
fi

if [ -z "${PIPELINE_STEP_INTAKE}" ] # In this case use the default, if earlier code didn't previously inject it
    then
        export PIPELINE_STEP_INTAKE=${PIPELINE_STEP_OUTPUT}
fi

echo "${_SVC__INFO_PROMPT} PIPELINE_STEP_INTAKE = ${PIPELINE_STEP_INTAKE}"
echo
echo "${_SVC__INFO_PROMPT} PIPELINE_STEP_OUTPUT = ${PIPELINE_STEP_OUTPUT}"
echo

# Check pipeline folder in the album contains a definition script
  [ ! -f "${_CFG__PIPELINE_ALBUM}/${PIPELINE_NAME}/pipeline_definition.sh" ] && echo \
  && echo "${_SVC__ERR_PROMPT} '${_CFG__PIPELINE_ALBUM}/${PIPELINE_NAME}' is improperly configured:" \
  && echo "${_SVC__ERR_PROMPT} It should contain a 'pipeline_definition'.sh file " \
  && echo "with two functions called '_CFG__pipeline_description' and '_CFG__pipeline_short_description'" \
  && echo \
  && exit 1

# Get the pipeline definition (i.e., set environment variables and initialize functions as per the definition for
# the pipeline with id $1
source "${_CFG__PIPELINE_ALBUM}/${PIPELINE_NAME}/pipeline_definition.sh"

# Check that Docker is running
docker stats --no-stream 2>/tmp/error 1>/dev/null
if [[ $? != 0 ]]; then
    error=$(</tmp/error)
    docker_down=$(echo $error | grep "Cannot connect to the Docker daemon" | wc -l)
    if [[ $docker_down == 1 ]]; then
        echo "${_SVC__ERR_PROMPT} Docker daemon not running, so must abort. In WSL you may start it from Bash by doing:"
        echo
        echo "   sudo service docker start"
        echo
        echo "...aborting script '$0'"
    else
        echo "${_SVC__ERR_PROMPT} Docker seems to be running but is giving errors:"
        echo
        echo $error
    fi
    exit 1
else
    echo "${_SVC__INFO_PROMPT} Verified that Docker daemon is running"
fi

if [ ! -z ${_CFG__DEPLOYABLE_IMAGE} ]
    then
        echo
        echo "${_SVC__INFO_PROMPT} Will be working with ${_CFG__DEPLOYABLE} image '${_CFG__DEPLOYABLE_IMAGE}'"
        echo
fi
