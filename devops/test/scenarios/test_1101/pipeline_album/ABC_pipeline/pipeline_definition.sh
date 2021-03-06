#!/usr/bin/env bash

# This variable holds a text description of what this pipeline does. This is needed by the discover_pipelines.sh
# script to help DevOps operators discover which pipeline to use by interrogating pipelines on what their purpose is.
# So this variable is required for all pipelines.
_CFG__pipeline_description() {
    echo "
    Pipeline used during test of the provisioning pipeline step

    Apodexi version built:              ${_CFG__DEPLOYABLE_GIT_BRANCH}
    Packaged as:                        Docker container from image ${_CFG__DEPLOYABLE_IMAGE}
    Deployed to:                        Local Linux host (same host in which pipeline is run)
    "
}

# Single-line description suitable for use when listing multiple pipelines
_CFG__pipeline_short_description() {
    echo "Used to test provisioning pipeline step"
}

export _CFG__UBUNTU_IMAGE="ubuntu:20.04"
export _CFG__PYTHON_VERSION="3.9"

# Release version that is to be built
export _CFG__DEPLOYABLE_GIT_BRANCH="v0.9.8"
export _CFG__DEPLOYABLE_VERSION="0.9.8"
export _CFG__DEPLOYABLE="apodeixi"
export _CFG__APPLICATION="${_CFG__DEPLOYABLE}"
export _CFG__APPLICATION_BASE_IMAGE="${_CFG__APPLICATION}-base"

export _CFG__DEPLOYABLE_GIT_URL="https://github.com/ChateauClaudia-Labs/${_CFG__DEPLOYABLE}.git"

# Define which server image to use for the build. Determines version of Ubuntu and Python for the container where the build runs
export _CFG__BUILD_SERVER="a6i-build-server"

# Defines the name (& tag) for the ${_CFG__DEPLOYABLE} image to be created by the pipeline. If there is no tag, Docker will
# by default put a tag of ":latest"
#
_CFG__DEPLOYABLE_IMAGE="${_CFG__DEPLOYABLE}:test_1101"