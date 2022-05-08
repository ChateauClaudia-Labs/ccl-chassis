#!/usr/bin/env bash

# This variable holds a text description of what this pipeline does. This is needed by the discover_pipelines.sh
# script to help DevOps operators discover which pipeline to use by interrogating pipelines on what their purpose is.
# So this variable is required for all pipelines.
pipeline_description() {
    echo "
    Pipeline used during test of the testrun pipeline step

    Apodexi version built:              ${_CFG__DEPLOYABLE_GIT_BRANCH}
    Packaged as:                        Docker container from image 'apodeixi:test_1101'
    Deployed to:                        Local Linux host (same host in which pipeline is run)
    "
}

# Single-line description suitable for use when listing multiple pipelines
pipeline_short_description() {
    echo "Used to test testrun pipeline step"
}

export UBUNTU_IMAGE="ubuntu:20.04"
export PYTHON_VERSION="3.9"
export UBUNTU_PYTHON_PACKAGE="python3.9"

# Release version that is to be built
export _CFG__DEPLOYABLE_GIT_BRANCH="v0.9.8"
export _CFG__DEPLOYABLE_VERSION="0.9.8"

export APODEIXI_GIT_URL="https://github.com/ChateauClaudia-Labs/apodeixi.git"

export APODEIXI_TESTDB_GIT_URL="https://github.com/ChateauClaudia-Labs/apodeixi-testdb.git"

# Define which server image to use for the build. Determines version of Ubuntu and Python for the container where the build runs
export A6I_BUILD_SERVER="a6i-build-server"

# Defines the name (& tag) for the Apodeixi image to be created by the pipeline. If there is no tag, Docker will
# by default put a tag of ":latest"
#
_CFG__DEPLOYABLE_IMAGE="apodeixi:test_1101"

# Defines what Apodeixi environment is being mounted in the Apodeixi container by this pipeline
#
#export ENVIRONMENT="TEST_ENV"

#export SECRETS_FOLDER=${PIPELINE_STEP_INTAKE}/${ENVIRONMENT}/secrets
#export COLLABORATION_AREA=${PIPELINE_STEP_INTAKE}/${ENVIRONMENT}/collaboration_area
#export KNOWLEDGE_BASE_FOLDER=${PIPELINE_STEP_INTAKE}/${ENVIRONMENT}/kb

#export APODEIXI_CONFIG_DIRECTORY=${PIPELINE_STEP_INTAKE}/${ENVIRONMENT}

# This is needed to tell the deployment stage to stop Docker, since when using Bats to test code that starts
# containers Bats will hang until the Docker container is stopped.
#   For real production deployment, the pipeline_definition should never set this variable
#
export RUNNING_BATS=1

export TEST_APODEIXI_CONFIG_DIRECTORY=${_CFG__PIPELINE_ALBUM}/${PIPELINE_NAME}/apodeixi_testdb_config