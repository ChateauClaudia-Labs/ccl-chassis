#!/usr/bin/env bash

# This variable holds a text description of what this pipeline does. This is needed by the discover_pipelines.sh
# script to help DevOps operators discover which pipeline to use by interrogating pipelines on what their purpose is.
# So this variable is required for all pipelines.
_CFG__pipeline_description() {
    echo "
    Pipeline used during test of the testrun pipeline step

    Apodexi version built:              ${_CFG__DEPLOYABLE_GIT_BRANCH}
    Packaged as:                        Docker container from image ${_CFG__DEPLOYABLE_IMAGE}
    Deployed to:                        Local Linux host (same host in which pipeline is run)
    "
}

# Single-line description suitable for use when listing multiple pipelines
_CFG__pipeline_short_description() {
    echo "Used to test testrun pipeline step"
}

export _CFG__UBUNTU_IMAGE="ubuntu:20.04"
export _CFG__PYTHON_VERSION="3.9"
export _CFG__UBUNTU_PYTHON_PACKAGE="python3.9"

# Release version that is to be built
export _CFG__DEPLOYABLE_GIT_BRANCH="v0.9.8"
export _CFG__DEPLOYABLE_VERSION="0.9.8"
export _CFG__DEPLOYABLE="apodeixi"

# Define which server image to use for the build. Determines version of Ubuntu and Python for the container where the build runs
export _CFG__BUILD_SERVER="a6i-build-server"

# Defines the name (& tag) for the ${_CFG__DEPLOYABLE} image to be created by the pipeline. If there is no tag, Docker will
# by default put a tag of ":latest"
#
export _CFG__DEPLOYABLE_IMAGE="${_CFG__DEPLOYABLE}:test_1101"


export TEST_APODEIXI_CONFIG_DIRECTORY=${_CFG__PIPELINE_ALBUM}/${PIPELINE_NAME}/apodeixi_testdb_config
export _CFG__TESTDB_GIT_URL="https://github.com/ChateauClaudia-Labs/apodeixi-testdb.git"

_CFG__set_testrun_docker_options() {
  
    echo    " -e _CFG__TESTDB_GIT_URL=${_CFG__TESTDB_GIT_URL} " \
            " -e INJECTED_CONFIG_DIRECTORY=/home/apodeixi_testdb_config" \
            " -e APODEIXI_CONFIG_DIRECTORY=/home/apodeixi_testdb_config" \
            " -v $TEST_APODEIXI_CONFIG_DIRECTORY:/home/apodeixi_testdb_config" \
            "${GIT_REPO_MOUNT_DOCKER_OPTION} "> /tmp/_CFG__TESTRUN_DOCKER_OPTIONS.txt
    export _CFG__TESTRUN_DOCKER_OPTIONS=`cat /tmp/_CFG__TESTRUN_DOCKER_OPTIONS.txt`
}

# This is needed to tell the deployment stage to stop Docker, since when using Bats to test code that starts
# containers Bats will hang until the Docker container is stopped.
#   For real production deployment, the pipeline_definition should never set this variable
#
export RUNNING_BATS=1