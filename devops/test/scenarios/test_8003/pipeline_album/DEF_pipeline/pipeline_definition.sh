#!/usr/bin/env bash

# This variable holds a text description of what this pipeline does. This is needed by the discover_pipelines.sh
# script to help DevOps operators discover which pipeline to use by interrogating pipelines on what their purpose is.
# So this variable is required for all pipelines.
pipeline_description() {
    echo "
    Pipeline used to test if 'apdo pipeline list' works properly

    Apodexi version built:              v0.9.7
    Packaged as:                        Docker container
    Deployed to:                        Host 'REMOTE_MACHINE'
    "
}

# Single-line description suitable for use when listing multiple pipelines
pipeline_short_description() {
    echo "Used to test deploying Apodeixi v0.9.7 as a Linux container to a remote node"
}

# Release version that is to be built
export APODEIXI_GIT_BRANCH="v0.9.7"
export APODEIXI_VERSION="0.9.7"

export APODEIXI_GIT_URL="https://github.com/ChateauClaudia-Labs/apodeixi.git"

# Define which server image to use for the build. Determines version of Ubuntu and Python for the container where the build runs
export A6I_BUILD_SERVER="a6i-build-server"