# ccl-chassis

Collection of tools, modules and utilities supporting common patterns applied across applications from ChateauClaudia-Labs.

Under this pattern:

* Application is built on Python
* The application consists of a number of server-side and client-side deployables.
* There are two logical operators in productions: 
    * One operator entity is responsible for client-side deployables. For example, the person/entity responsible for 
      user laptos where the client-side deployables run.
    * Another operator entity is responsible for server-side deployable. For example, the person/entity responsible
      for the cloud or datacenter deployment of Docker containers/K8s cluster where server-side deployables run.
* The application's code is organized into two repos, one for each type of operator. This makes it easier for developers
  to ensure that for a given operator all the deployables it receives are consistent and mutually tested. Therefore, we have:
    * One repo for all client-side deployables.
    * Another repo for server-side deployables 
* Each repo contains separate folders per deployable
* Each deployable is a Python project with a dedicated setup.py (i.e., each deployable can be built into a separate
  Python package, either a wheel or Conda package)
* There is at least 1 client deployable: a CLI
* There are 0-N server-side deployables, each of which is a Docker container. If there are no server containers, then
  the client-side CLI is a "fat client" (effectively, the application is a desktop app in that case)
* It is common to allow the application to support two deploymnent modes, with the choice made in the CI/CD configuration:
    * N-tier: light CLI client + N Docker services
    * Desktop: fat CLI client
* CI/CD is handled by the `devops` project that is part of the CCL Chassis's GIT repo. We refer you to the dedicated 
  README.md in that project. Some highlights:
    * It means that each application repo has 1 or more pipeline albums (one per deployable)

# Installing certain dependencies as GIT submodules

GIT submodule functionality is used to inject dependencies into this project. So after cloning this project, you will
need to set up the following submodules of the `ccl-chassis` GIT project.
Without them some of the CCL-Chassis' modules, such as CCL-DevOps, would not work properly.

When the repo was created, this was done (you don't need to do this if cloning - read below):

`git submodule add https://github.com/bats-core/bats-core.git bats`
`git submodule add https://github.com/bats-core/bats-support.git bats_helpers/bats-support`
`git submodule add https://github.com/bats-core/bats-assert.git bats_helpers/bats-assert`
`git submodule add https://github.com/bats-core/bats-file.git bats_helpers/bats-file`

If you clone this repo, then you must do this instead (as `git submodule add` would give you errors):

In the root for the CCL Chassis repo, do:

`git submodule init`
`git submodule update --remote`

From time to time these submodules should updated, by doing 

`git submodule update --remote` in the local folder for the submodules.

See https://git-scm.com/book/en/v2/Git-Tools-Submodules for more details on how to admnister GIT submodules.
