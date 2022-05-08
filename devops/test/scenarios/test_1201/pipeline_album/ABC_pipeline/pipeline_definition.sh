#!/usr/bin/env bash

# This variable holds a text description of what this pipeline does. This is needed by the discover_pipelines.sh
# script to help DevOps operators discover which pipeline to use by interrogating pipelines on what their purpose is.
# So this variable is required for all pipelines.
_CFG__pipeline_description() {
    echo "
    Pipeline used during test of the deployment pipeline step

    Apodexi version built:              ${_CFG__DEPLOYABLE_GIT_BRANCH}
    Packaged as:                        Docker container from image 'apodeixi:test_1201'
    Deployed to:                        Local Linux host (same host in which pipeline is run)
    "
}

# Single-line description suitable for use when listing multiple pipelines
_CFG__pipeline_short_description() {
    echo "Used to test deployment pipeline step"
}

export _CFG__UBUNTU_IMAGE="ubuntu:20.04"
export PYTHON_VERSION="3.9"

# Release version that is to be built
export _CFG__DEPLOYABLE_GIT_BRANCH="v0.9.8"
export _CFG__DEPLOYABLE_VERSION="0.9.8"

export _CFG__DEPLOYABLE_GIT_URL="https://github.com/ChateauClaudia-Labs/apodeixi.git"

# Define which server image to use for the build. Determines version of Ubuntu and Python for the container where the build runs
export _CFG__BUILD_SERVER="a6i-build-server"

# Defines the name (& tag) for the Apodeixi image to be created by the pipeline. If there is no tag, Docker will
# by default put a tag of ":latest"
#
export _CFG__DEPLOYABLE_IMAGE="apodeixi:test_1101"
export _CFG__DEPLOYABLE="apodeixi"


# These are inputs to the setting of _CFG__DEPLOYMENT_DOCKER_OPTIONS
#
# That means that they determine what Apodeixi environment is being mounted in the Apodeixi container by 
# this pipeline.
# That's mediated by the function epoch_commons.sh::_CFG__set_deployment_docker_options, which uses
# these inputs to define _CFG__DEPLOYMENT_DOCKER_OPTIONS
#
# The function _CFG__set_deployment_docker_options is invoked by CCL-DevOps
#
export ENVIRONMENT="TEST_ENV"
export SECRETS_FOLDER=${PIPELINE_STEP_INTAKE}/${ENVIRONMENT}/secrets
export COLLABORATION_AREA=${PIPELINE_STEP_INTAKE}/${ENVIRONMENT}/collaboration_area
export KNOWLEDGE_BASE_FOLDER=${PIPELINE_STEP_INTAKE}/${ENVIRONMENT}/kb

export APODEIXI_CONFIG_DIRECTORY=${PIPELINE_STEP_INTAKE}/${ENVIRONMENT}

_CFG__set_deployment_docker_options() {

    # Check that Apodeixi config file exists
    [ ! -f ${APODEIXI_CONFIG_DIRECTORY}/apodeixi_config.toml ] && echo \
        && echo "${_SVC__ERR_PROMPT} '${_CFG__PIPELINE_ALBUM}/${PIPELINE_NAME}' is improperly configured:" \
        && echo "${_SVC__ERR_PROMPT} It expects Apodeixi config file, which doesn't exist:" \
        && echo "${_SVC__ERR_PROMPT}     ${APODEIXI_CONFIG_DIRECTORY}/apodeixi_config.toml" \
        && echo \
        && exit 1

    # Check that mounted volumes for the Apodeixi environment exist
    [ ! -d ${SECRETS_FOLDER} ] && echo \
            && echo "${_SVC__ERR_PROMPT} '${_CFG__PIPELINE_ALBUM}/${PIPELINE_NAME}' is improperly configured:" \
            && echo "${_SVC__ERR_PROMPT} It expects a non-existent folder called "\
            && echo "    ${SECRETS_FOLDER}." \
            && echo \
            && exit 1
    [ ! -d ${COLLABORATION_AREA} ] && echo \
            && echo "${_SVC__ERR_PROMPT} '${_CFG__PIPELINE_ALBUM}/${PIPELINE_NAME}' is improperly configured:" \
            && echo "${_SVC__ERR_PROMPT} It expects a non-existent a folder called " \
            && echo "    ${COLLABORATION_AREA}." \
            && echo \
            && exit 1
    [ ! -d ${KNOWLEDGE_BASE_FOLDER} ] && echo \
        && echo "${_SVC__ERR_PROMPT} '${_CFG__PIPELINE_ALBUM}/${PIPELINE_NAME}' is improperly configured:" \
        && echo "${_SVC__ERR_PROMPT} It expects a non-existent a folder called " \
        && echo "    ${KNOWLEDGE_BASE_FOLDER}." \
            && echo \
    && exit 1

    echo    " -e APODEIXI_CONFIG_DIRECTORY=/home/apodeixi/config" \
            " -v ${SECRETS_FOLDER}:/home/apodeixi/secrets " \
            " -v ${COLLABORATION_AREA}:/home/apodeixi/collaboration_area "\
            " -v ${KNOWLEDGE_BASE_FOLDER}:/home/apodeixi/kb " \
            " -v ${APODEIXI_CONFIG_DIRECTORY}:/home/apodeixi/config" > /tmp/_CFG__DEPLOYMENT_DOCKER_OPTIONS.txt

    export _CFG__DEPLOYMENT_DOCKER_OPTIONS=`cat /tmp/_CFG__DEPLOYMENT_DOCKER_OPTIONS.txt`

}

# This is needed to tell the deployment stage to stop Docker, since when using Bats to test code that starts
# containers Bats will hang until the Docker container is stopped.
#   For real production deployment, the pipeline_definition should never set this variable
#
export RUNNING_BATS=1