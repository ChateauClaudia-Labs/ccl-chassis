ARG _CFG__UBUNTU_IMAGE
FROM ${_CFG__UBUNTU_IMAGE}

# As recommended in https://rtfm.co.ua/en/docker-configure-tzdata-and-timezone-during-build/,
# setting non-interactive and (for good measure) the timezones here ensures that build won't hang 
# waiting for user input on what timezone
# to configure, and also so it does not hang waiting for what kind of keyboard to configure
ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=America/Los_Angeles
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

RUN apt update && apt upgrade -y

# Get required software (GIT, Python), pip). 
# Also set a symbolic link for "python" to the python we install (e.g., "python3.9") so that "python" is 
# treated like a Linux command
#
# GOTCHA: The version of Python in ${_CFG__UBUNTU_PYTHON_PACKAGE} may not be supported in the Ubuntu version
#       used for this Dockerfile (${_CFG__UBUNTU_IMAGE}). Make sure it is supported, else the commands below
#       will seem to work but the version of Python you want is not installed
RUN apt update
ARG _CFG__UBUNTU_PYTHON_PACKAGE
RUN echo "Will attempt to install ${_CFG__UBUNTU_PYTHON_PACKAGE}"
RUN apt-get install -y ${_CFG__UBUNTU_PYTHON_PACKAGE}
RUN ln -s $(which ${_CFG__UBUNTU_PYTHON_PACKAGE}) /usr/bin/python
# Verify that a python executable installed properly. Doing `which python` will return 1 (an error code) if above
# commands didn't install Python properly, which should cause this Dockerfile build to stop. 
#
#   TIP: If this failure happens, it may be because the version of Ubuntu used does not support this version of Python. Consider
#           using a more recent version of Ubuntu. 
#           For example, Python 3.10 can't be installed on Ubuntu 20.04 (libraries will seem to install, but not the
#           actual executable), whereas in Ubuntu 22.04 you get Python 3.10 by default (Ubuntu 20.04 has Python 3.8 by default and
#           supports installing Python 3.9)
# 
RUN echo "Checking if ${_CFG__UBUNTU_PYTHON_PACKAGE} installed properly by doing 'which python'" & which python

RUN apt-get install -y python3-pip

RUN apt install -y git


# As explained in https://devopscube.com/keep-docker-container-running/, to ensure that the build server keeps running
# after running build script, in case that we want to debug it, we must have an entrypoint:
#
ENTRYPOINT ["tail", "-f", "/dev/null"]


