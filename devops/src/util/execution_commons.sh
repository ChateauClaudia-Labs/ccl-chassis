# This file defines some common variables & functions used inexecution_pipeline.sh scripts
# across multiple pipelines.
#

# This function expects two arguments:
#   - $1: The name of a script from CCL-DevOps for docker flows. Example: "request_build.sh"
#   - $2: The step description for the user. Example: "build step"
execute_docker_flow_step() {

    # GOTCHA: Invoke pipeline steps so that $0 is set to their full path, since each step assumes
    #       $0 refers to that pipeline step's script. This means that:
    #       1. Invoke the script directly, not by using the 'source' command
    #       2. Invoke them via their full path
    #       3. To ensure environment variables referenced here are set, the caller should have invoked this script using 'source'
    #
    echo "${_SVC__INFO_PROMPT} Running $2..."
    T0=$SECONDS
    ${_SVC__ROOT}/src/docker_flow/pipeline_steps/$1 ${_SVC__PIPELINE_ID} &>> ${_SVC__PIPELINE_LOG}
    abort_pipeline_step_on_error
    T1=$SECONDS
    echo "${_SVC__INFO_PROMPT} ... completed $2 in $(($T1 - $T0)) sec"

}

# This function expects two arguments:
#   - $1: The name of a script from CCL-DevOps for docker flows. Example: "request_linux_condabuild"
#   - $2: The step description for the user. Example: "Linux conda build step"
execute_conda_flow_step() {

    # GOTCHA: Invoke pipeline steps so that $0 is set to their full path, since each step assumes
    #       $0 refers to that pipeline step's script. This means that:
    #       1. Invoke the script directly, not by using the 'source' command
    #       2. Invoke them via their full path
    #       3. To ensure environment variables referenced here are set, the caller should have invoked this script using 'source'
    #
    echo "${_SVC__INFO_PROMPT} Running $2..."
    T0=$SECONDS
    ${_SVC__ROOT}/src/conda_flow/pipeline_steps/$1 ${_SVC__PIPELINE_ID} &>> ${_SVC__PIPELINE_LOG}
    abort_pipeline_step_on_error
    T1=$SECONDS
    echo "${_SVC__INFO_PROMPT} ... completed $2 in $(($T1 - $T0)) sec"

}