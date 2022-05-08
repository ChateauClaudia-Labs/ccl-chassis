#!/usr/bin/env bash

# This variable holds a text description of what this pipeline does. This is needed by the discover_pipelines.sh
# script to help DevOps operators discover which pipeline to use by interrogating pipelines on what their purpose is.
# So this variable is required for all pipelines.
_CFG__pipeline_description() {
    echo "
    Pipeline used for test purposes only
    Apodexi version built:              ${_CFG__DEPLOYABLE_GIT_BRANCH}
    Packaged as:                        Docker container
    Deployed to:                        Local Linux host (same host in which pipeline is run)
    "
}

# Single-line description suitable for use when listing multiple pipelines
_CFG__pipeline_short_description() {
    echo "Used to test building Apodeixi ${_CFG__DEPLOYABLE_GIT_BRANCH} as a Linux container locally"
}

export UBUNTU_IMAGE="ubuntu:20.04"
export PYTHON_VERSION="3.9"

# Release version that is to be built
export _CFG__DEPLOYABLE_GIT_BRANCH="v0.9.8"
export _CFG__DEPLOYABLE_VERSION="0.9.8"
export _CFG__DEPLOYABLE="apodeixi"

_CFG__set_build_docker_options() {

    APODEIXI_GIT_URL="https://github.com/ChateauClaudia-Labs/apodeixi.git"  

    export _CFG__BUILD_DOCKER_OPTIONS=" -e APODEIXI_GIT_URL=${APODEIXI_GIT_URL} "
}

# Define which server image to use for the build. Determines version of Ubuntu and Python for the container where the build runs
export A6I_BUILD_SERVER="a6i-build-server"

# This is needed to tell the deployment stage to stop Docker, since when using Bats to test code that starts
# containers Bats will hang until the Docker container is stopped.
#   For real production deployment, the pipeline_definition should never set this variable
#
export RUNNING_BATS=1