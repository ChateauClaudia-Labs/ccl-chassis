#!/usr/bin/env bash

# Script to implement the behavior of the `apdo pipeline` command for the `apdo` CLI

source ${_SVC__ROOT}/bin/util/apdo-common.sh

# Check that a command  passed as argument $1. Set the error message to use in $ERROR_MSG
export ERR_MSG="pipeline command requires a subcommand to be given"
cli_argument_exists $1

# Dispatch to the interpreter for the right command ($1 is the command)
case "$1" in
  list)         ${_SVC__ROOT}/bin/commands/pipeline-list.sh ${@:2};; # $@ is an array of all arguments, so ${@:2} is a slice from 2nd elt onwards
  describe)     ${_SVC__ROOT}/bin/commands/pipeline-describe.sh ${@:2};;
  run)          ${_SVC__ROOT}/bin/commands/pipeline-run.sh ${@:2};;
  *)            echo "${ERROR_PROMPT} Invalid apdo pipeline subcommand '${1}'"
                cli_help
                exit 1;;
esac
