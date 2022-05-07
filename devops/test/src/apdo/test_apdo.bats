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
    cd $PROJECT_ROOT/bin
}

setup() {
    _set_project_root

    load '../util/common-setup'
    _test_case_setup
    echo "================ $BATS_TEST_NAME ==========" >> $TEST_LOG
}

@test "8001" {
    echo "_______Test case description: apdo help" >> $TEST_LOG

    run ./apdo --help

    echo "_______status: ${status}" >> $TEST_LOG
    echo "_______output:" >> $TEST_LOG
    echo "$output" >> $TEST_LOG

    # Check we got the expected output
    _compare_to_expected

    # Validate that there are no errors in the log. And if we have errors, this will display the first one
    refute_line --partial "${ERR_PROMPT}"

    # Even if there are no errors in the log, if something more fatal happened, catch it here
    assert [ ${status} -eq 0 ]
}

@test "8002" {
    echo "_______Test case description: apdo pipeline describe ABC" >> $TEST_LOG

    run ./apdo pipeline describe ABC

    echo "_______status: ${status}" >> $TEST_LOG
    echo "_______output:" >> $TEST_LOG
    echo "$output" >> $TEST_LOG

    # Check we got the expected output
    expected_output=`cat ${SCENARIO_INPUTS_FOLDER}/expected_output.txt`
    _compare_to_expected

    # Validate that there are no errors in the log. And if we have errors, this will display the first one
    refute_line --partial "${ERR_PROMPT}"

    # Even if there are no errors in the log, if something more fatal happened, catch it here
    assert [ ${status} -eq 0 ]
}

@test "8003" {
    echo "_______Test case description: apdo pipeline list" >> $TEST_LOG

    run ./apdo pipeline list

    echo "_______status: ${status}" >> $TEST_LOG
    echo "_______output:" >> $TEST_LOG
    echo "$output" >> $TEST_LOG

    # Check we got the expected output
    expected_output=`cat ${SCENARIO_INPUTS_FOLDER}/expected_output.txt`
    _compare_to_expected

    # Validate that there are no errors in the log. And if we have errors, this will display the first one
    refute_line --partial "${ERR_PROMPT}"

    # Even if there are no errors in the log, if something more fatal happened, catch it here
    assert [ ${status} -eq 0 ]
}

teardown() {
    _generic_teardown  
}

teardown_file() {

    echo "Nothing to tear down in file" > /dev/null

}