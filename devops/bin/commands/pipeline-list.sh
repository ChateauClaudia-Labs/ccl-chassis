#!/usr/bin/env bash

# Script to implement the behavior of the `apdo pipeline list` command for the `apdo` CLI

source ${_SVC__ROOT}/bin/util/apdo-common.sh

# directories under the album are in the form <ID>_pipeline. So to ghet the ID, split by delimeter "_pipeline"
# We achieve this by piping the list of relative directory names to the 'tr' translate command, that will replace the 
# '_pipeline' by newlines
pipeline_ids=$(ls ${_CFG__PIPELINE_ALBUM}/ | grep "_pipeline" | tr "_pipeline" "\n")

echo # empty line for readability
for id in $pipeline_ids
do
    # Check that pipeline folder includes a pipeline definition
    cli_pipeline_def_exists ${_CFG__PIPELINE_ALBUM} ${id}_pipeline

    # Get definition (really more of a config) of the pipeline we are running
    source "${_CFG__PIPELINE_ALBUM}/${id}_pipeline/pipeline_definition.sh"
    _CFG__pipeline_short_description > /tmp/pipeline_short_desc
    desc=$(</tmp/pipeline_short_desc)
    echo "$id           $desc"
done
echo # empty line for readability
