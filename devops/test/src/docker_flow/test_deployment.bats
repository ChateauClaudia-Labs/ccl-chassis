#!/usr/bin/env bash

_set_project_root() {
    # get the containing directory of this file
    # use $BATS_TEST_FILENAME instead of ${BASH_SOURCE[0]} or $0,
    # as those will point to the bats executable's location or the preprocessed file respectively
    PROJECT_ROOT="$( cd "$( dirname "$BATS_TEST_FILENAME" )/../../../" >/dev/null 2>&1 && pwd )"    
}

setup_file() {
    _set_project_root

    load '../util/common-setup'
    _test_file_setup
    cd $PROJECT_ROOT/src/docker_flow/pipeline_steps
}

setup() {
    _set_project_root

    load '../util/common-setup'
    _test_case_setup
    echo "================ $BATS_TEST_NAME ==========" >> $TEST_LOG
}

@test "1201" {
    # DEVELOPMENT DEBUG - Uncomment to keep output while debugging
    #export KEEP_TEST_OUTPUT=1

    # Temporarily "pretend" we want to keep output, in case we exit before the end of this function, when we
    # restore the original value 
    export ORIGINAL_KEEP_TEST_OUTPUT=$KEEP_TEST_OUTPUT
    export KEEP_TEST_OUTPUT=1

    echo "_______Test case description: deployment stage" >> $TEST_LOG

    run ./request_deployment.sh "ABC"

    echo "_______status: ${status}" >> $TEST_LOG
    echo "_______output:" >> $TEST_LOG
    echo "$output" >> $TEST_LOG

    # Validate that there are no errors in the log. And if we have errors, this will display the first one
    refute_line --partial "${ERR_PROMPT}"

    # Even if there are no errors in the log, if something more fatal happened, catch it here
    assert [ ${status} -eq 0 ]

    # SUCCESS!  Got ths far without problems, so restore original
    #       If we don't get here, then something went wrong and we don't want the original, to force teardown to retain
    #       output, logs, etc., to help with debugging.
    export KEEP_TEST_OUTPUT=$ORIGINAL_KEEP_TEST_OUTPUT
}

teardown() {
    _generic_teardown  
}

teardown_file() {

    echo "Nothing to tear down in file" > /dev/null

}