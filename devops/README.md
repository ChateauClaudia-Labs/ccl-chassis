# CCL-DevOps

CI/CD machinery for CCL applications that adhere to the patterns supported by the CCL Chassis. See the README.md for the CCL Chassis
for a description of those patterns.

Each application's repo is expected to contain a `pipeline_album`, which is a folder of pipeline definitions. Those definitions
are used by the DevOps module to instantiate and run CI/CD pipelines.

Each pipeline's definition in the `pipeline_album` determines what the pipeline does. This may vary, e.g., some will create
and deploy Docker containers, and others might create Conda packages or development-type transient distributions.

As an example, the Apodeixi application has pipelines that will:

* Build a distribution for Apodeixi, packaged as a multi-platform `wheel` artifact (i.e., works both in Windows and Linux)
* Create a Docker Apodeixi image with it, provisioning all
  dependencies required by Apodeixi.
* Start an Apodeixi container and run Apodeixi tests on it
* Deploy an Apodeixi container to a target environment

The CCL-DevOps machinery is implemented as a suite of Bash scripts.

Pipelines running CCL-DevOps are only meant to be run in Linux, even if CCL applications like Apodeixi orten are 
multi-platform (Windows and Unix).

Windows developers must therefore rely on WSL to run CI/CD pipelines.

# Installing dependencies as GIT submodules

As explained in `../README.md` for the `ccl-chassis` git project of which CCL-DevOps is a module, there are some GIT
submodule dependencies.

Make sure all Bats dependencies are installed, since CCL-DevOps relies on them for its test harness.

# Pipeline Albums

Normally, your application project would contain a folder called `pipeline_album`, containing a subfolder per pipeline.
These subfolders are called something like `ABC_pipeline` or `1001_pipeline`, where `ABC` or `1001` are the identifiers
of the pipelines in the album.

Thus, for CCL-DevOps a specific pipeline is uniquely determined once you specify:
* The pipeline album, through the environment variable `$_CFG__PIPELINE_ALBUM`
* A pipeline id (such as `1001`) for a valid pipeline in such album (i.e, a valid definition file
  `$_CFG__PIPELINE_ALBUM/1001_pipeline/pipeline_definition.sh`, if the id is `1001`)
* Additionally, the master script for a pipeline that invokes steps from a CCl-DevOps installation must exist in
  `$_CFG__PIPELINE_ALBUM/1001_pipeline/execute pipeline.sh` (if the id is `1001`)

# Application-specific Configuration

CCL-DevOps is a collection on Bash scripts using a number of environment variables.

Variables whose name starts with `_CFG__...` or `SVC__` should be considered part of the public contract between CCL-DevOps
and the Applications that use them.

Ownership of such variables is as follows:

* Variables whose name starts with `_CFG__...` are owned by the application: each application sets its
  value (often in its pipeline definition Bash script), and CCL-DevOps makes use of them. If they refer to paths,
  those paths would typically be in the application installation area.

* Variables whose name starts with `_SVC__...` are owned by the CCL-DevOps: CCL-DevOps sets their
  value and Application scripts make use of them. If they refer to paths those paths would normally be in the
  CCL-DEVOPS installation area.

This is the list of variables that comprise such contract:

* _SVC__ROOT: points to the folder where CCL-DevOps is installed. Auto-configured by CCL-DevOps.

* _CFG__PIPELINE_ALBUM: points to the folder where an application's pipeline album resides. Must be set
                                    as an environment variable by the user, before CCL-DevOps runs.


# Running the CCL-DevOps pipelines

Docker must be running. If you are using a WSL environment, you can start the Docker daemon like this:

`sudo service docker start`

You must also set a couple of environment variables:

* Add the bin folder of your CCL-DevOps installation to `$PATH`. For example, 
  `export PATH=/mnt/c/Users/aleja/Documents/Code/chateauclaudia-labs/ccl-chassis/devops/bin:$PATH`
* `$_CFG__PIPELINE_ALBUM` to identify the folder containing the CCL-DevOps pipeline definitions for your application.
  Typically this would be a folder in your application repo.

Once Docker is running, you may run CCL-DevOps pipeline by, for example:

`apdo pipeline run 1001` (if `1001` is a valid pipeline id for the album you are pointing to)

# Running the tests for the pipeline itself

The CI/CD pipeline is a program (written as various Bash scripts), and it is tested using Bats (https://bats-core.readthedocs.io/en/stable/index.html), a testing framework for Bash scripts.

All tests and their tooling lies in the test folder.

To run all the tests, change directory to the root of the CCL-DevOps project and run this command in Bash:

`./bats/bin/bats -r test/src`

To run a particular test, replace `test` by its relative path. For example, to run the `test/test_build.bats`,
run this in Bash:

`./bats/bin/bats test/src/docker_flow/test_build.bats`

If tests fail and we need to see the temporary output (e.g., logs and such), set this environment variable before running
the tests:

`export KEEP_TEST_OUTPUT=1`

and later unset it when you no longer want to retain temporary output:

`unset KEEP_TEST_OUTPUT`



