#!/usr/bin/env bash

export INFO_PROMPT="[APDO INFO]"
export ERROR_PROMPT="[APDO ERROR]"

# The _CFG__PIPELINE_HISTORY is the root folder where pipeline runs store all their output, logs, etc.,
# organized in subfolders per pipeline name, then by run for each pipeline.
#
#   If it is not set, we will assume that output shoud be saved in the album definition itself.
if [ -z "${_CFG__PIPELINE_HISTORY}" ]
    then
        export _CFG__PIPELINE_HISTORY=${_CFG__PIPELINE_ALBUM}/../apdo_builds
fi

cli_help() {
  echo "
  ------------- Help for apdo:
  
    This utility is intended to help DevOps operators of an application built with the CCL Chassis.

    Requires that '\$_CFG__PIPELINE_ALBUM' be set pointing to the pipeline album folder for the application in question. 

    Available commands:

      apdo --help                           Shows this help message
      apdo pipeline list                    List of all pipeline IDs
      apdo pipeline describe <pipeline ID>  Describes what is deployed by given pipeline
      apdo pipeline run <pipeline ID>       Runs given pipeline
  "
}

# Function takes two arguments: the argument to test for void, and the error message to display if it is blank
cli_argument_exists() {
  if [ -z "$1" ]
    then
      echo "${ERROR_PROMPT} ${ERR_MSG}"
      cli_help
      exit 1
  fi
}

# We require that a pipeline "album" has been injected. A pipeline "album"
# is simply a folder with subfolders called <ID>_pipeline, where <ID> identifies a pipeline in the "album".
# Teach <ID>_pipeline folder contains subfolder for runs on the pipeline (logs, output, ...) and also contains a file
# defining the pipeline ('pipeline_definition.sh'). This definition is interpreted by DevOps' code to run the 
# the generic pipeline steps but as configured specifically for the pipeline idenfified by <ID>
#
# So we require that the caller has set the variable ${_CFG__PIPELINE_ALBUM}, we use that; else we default it
#
if [ -z "${_CFG__PIPELINE_ALBUM}" ]
    then
        echo "${ERROR_PROMPT} Command can't be processed because environment variable '_CFG__PIPELINE_ALBUM' is not set"
        exit 1
fi


# Check that there is a pipeline for this id. $1 should be ${_CFG__PIPELINE_ALBUM} and $2 should be ${PIPELINE_NAME}
cli_pipeline_exists() {
  [ ! -d "${1}/${2}" ] && echo \
  && echo "${ERROR_PROMPT} '${2}' is not a valid ID for a pipeline" \
  && echo "${ERROR_PROMPT} Try 'apdo pipeline list' to view a list of available pipeline IDs" \
  && echo \
  && exit 1
}

# Check that pipeline folder includes a pipeline definition. $1 should be ${_CFG__PIPELINE_ALBUM} and $2 should be ${PIPELINE_NAME}
cli_pipeline_def_exists() {
  [ ! -f "${1}/${2}/pipeline_definition.sh" ] && echo \
  && echo "${ERROR_PROMPT} '${2}' is improperly configured:" \
  && echo "${ERROR_PROMPT} It should contain a 'pipeline_definition.sh' file " \
  && echo "with two functions called '_CFG__pipeline_description' and '_CFG__pipeline_short_description'" \
  && echo \
  && exit 1
}

# Check that pipeline folder includes the script that runs the pipeline. $1 should be ${_CFG__PIPELINE_ALBUM} and $2 should be ${PIPELINE_NAME}
cli_pipeline_run_exists() {
  [ ! -f "${1}/${2}/execute_pipeline.sh" ] && echo \
  && echo "${ERROR_PROMPT} '${2}' is improperly configured:" \
  && echo "${ERROR_PROMPT} It should contain a 'execute_pipeline.sh' file responsible for running all steps of pipeline" \
  && echo \
  && exit 1
}

abort_pipeline_step_on_error() {
    if [[ $? != 0 ]]; then
      echo
      echo "${ERROR_PROMPT} Pipeline aborted."
      echo "${ERROR_PROMPT} See error logs at ${_SVC__PIPELINE_LOG}"
      echo
      exit 1
    fi
}