#!/usr/bin/env bash

# Requires ${PROJECT_ROOT} to be set beforehand
_test_case_setup() {
    load "${PROJECT_ROOT}/../bats_helpers/bats-support/load"
    load "${PROJECT_ROOT}/../bats_helpers/bats-assert/load"
    load "${PROJECT_ROOT}/../bats_helpers/bats-file/load"

    # Should uniquely identify the test in the test run
    export TESTCASE_ID="${BATS_TEST_NAME}"

    # Folder for temporary test output
    export TESTCASE_OUTPUT_DIR="${PROJECT_ROOT}/test/output/${TIMESTAMP}_${TESTCASE_ID}"
    if [ ! -d "${PROJECT_ROOT}/test/output" ]
        then
            mkdir "${PROJECT_ROOT}/test/output"
    fi

    mkdir ${TESTCASE_OUTPUT_DIR}

    # For tests, use a test-specific folder for inputs. In particular, for the pipeline album, 
    # instead of the default "production" album meant for "real" pipelines
    export SCENARIO_INPUTS_FOLDER=${PROJECT_ROOT}/test/scenarios/${TESTCASE_ID}
    export _CFG__PIPELINE_ALBUM=${SCENARIO_INPUTS_FOLDER}/pipeline_album

    # Folder where pipeline steps write their output to
    export PIPELINE_STEP_OUTPUT="${TESTCASE_OUTPUT_DIR}/pipeline_run"

    # Folder from which pipeline steps intake data created in upstream pipeline steps.
    # We inject a non-default value for test cases
    export PIPELINE_STEP_INTAKE="${SCENARIO_INPUTS_FOLDER}/pipeline_step_intake"

    # File in which to log output from the tests
    export TEST_LOG="${TESTCASE_OUTPUT_DIR}/test_log.txt"
    touch ${TEST_LOG}
}

_test_file_setup() {

    # make executables in src/ visible to PATH
    PATH="$PROJECT_ROOT/src:$PATH"

    # Unique timestamp used e.g., as a prefix in the names of log files
    export TIMESTAMP="$(date +"%y%m%d.%H%M%S")"

    # Log entry prefixes used by CCL-DevOps
    export _SVC__ERR_PROMPT="[A6I CI/CD ERROR]"
    export _SVC__INFO_PROMPT="[A6I CI/CD INFO]"

}

# Expects these to have been set beforehand:
#       - ${SCENARIO_INPUTS_FOLDER}
#       = $TEST_LOG
#       - $output (the output of the test case being run)
_compare_to_expected() {
    expected_output=`cat ${SCENARIO_INPUTS_FOLDER}/expected_output.txt`
    # GOTCHA: found the hard way that I can't use a variable to store value of expression [ "$expected_output" == "$output" ]
    #           So that is why this expression appears twice in the next few lines
    if [ "$expected_output" == "$output" ]
        then 
            match_msg=":-)   it matches!"
        else 
            match_msg=":-(  doesn't match"; 
            export OUTPUT_DOES_NOT_MATCH_EXPECTED=1 # Force that output be kept
    fi
    echo "_______output matches expected?          $match_msg" >> $TEST_LOG

    assert [ "$expected_output" == "$output" ]
}

# This is the default logic for a test case teardown.
# It can be called by a bats test file's teardown function as a way to re-use generic teardown functionality across tests.
_generic_teardown() {

    if [[ 0 != ${status} ]] # Invocation of DevOps functionality triggered an error
        then
            echo "# " >&3
            echo "# DevOps services failed with status $status, so output is being kept at:" >&3
            echo "#       ${TESTCASE_OUTPUT_DIR}" >&3

    elif [[ ! -z $OUTPUT_DOES_NOT_MATCH_EXPECTED ]] # DevOps services ran OK, but expected output did not match
        then 
            # As per Bats documentation (https://bats-core.readthedocs.io/en/stable/writing-tests.html#printing-to-the-terminal),
            # we must redirect to 3 if we want to force printing information to the terminal
            echo "# " >&3
            echo "# Test output doesn't match expected. Output is being kept at:" >&3
            echo "#       ${TESTCASE_OUTPUT_DIR}" >&3  
    elif [[ ! -z $KEEP_TEST_OUTPUT ]] # Test passed, but user had set $KEEP_TEST_OUTPUT
        then 
            # As per Bats documentation (https://bats-core.readthedocs.io/en/stable/writing-tests.html#printing-to-the-terminal),
            # we must redirect to 3 if we want to force printing information to the terminal
            echo "# " >&3
            echo "# Test output is being kept at:" >&3
            echo "#       ${TESTCASE_OUTPUT_DIR}" >&3 
            echo "# " >&3
            echo "# Do 'unset KEEP_TEST_OUTPUT' in command line to discard future output" >&3 
        
    else
        # Nothing seems to have gone wrong, nor has user asked to retain output, so no need to retain output
        rm -rf ${TESTCASE_OUTPUT_DIR}
    fi    
}