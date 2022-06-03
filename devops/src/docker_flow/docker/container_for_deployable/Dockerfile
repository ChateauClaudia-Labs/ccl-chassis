ARG _CFG__UBUNTU_IMAGE
FROM ${_CFG__UBUNTU_IMAGE}
RUN apt update && apt upgrade -y

ARG _CFG__DEPLOYABLE_VERSION
ARG _CFG__DEPLOYABLE

# As recommended in https://rtfm.co.ua/en/docker-configure-tzdata-and-timezone-during-build/,
# setting non-interactive and (for good measure) the timezones here ensures that build won't hang 
# waiting for user input on what timezone
# to configure, and also so it does not hang waiting for what kind of keyboard to configure
ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=America/Los_Angeles
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

COPY ./${_CFG__DEPLOYABLE}-${_CFG__DEPLOYABLE_VERSION}-py3-none-any.whl /home/${_CFG__DEPLOYABLE}/

# get-pip.py is needed so that we can dowload a version of pip that is compatible with the version of Python we are installing
COPY ./get-pip.py /home/tmp/

# Get required software (Python). 
# Also set a symbolic link for "python" to the python we install (e.g., "python3.9") so that "python" is 
# treated like a Linux command
#
ARG PYTHON_VERSION
# The Python install was failing until this `apt-get update` was added right before it
RUN apt update 
RUN apt install -y python${PYTHON_VERSION}

RUN ln -s $(which python${PYTHON_VERSION}) /usr/bin/python
# Verify that a python executable installed properly. Doing `which python` will return 1 (an error code) if above
# commands didn't install Python properly, which should cause this Dockerfile build to stop. 
#
#   TIP: If this failure happens, it may be because the version of Ubuntu used does not support this version of Python. Consider
#           using a more recent version of Ubuntu. 
#           For example, Python 3.10 can't be installed on Ubuntu 20.04 (libraries will seem to install, but not the
#           actual executable), whereas in Ubuntu 22.04 you get Python 3.10 by default (Ubuntu 20.04 has Python 3.8 by default and
#           supports installing Python 3.9)
# 
RUN echo "Checking if python${PYTHON_VERSION} installed properly by doing 'which python'" & which python

# Get pip - as suggested in https://stackoverflow.com/questions/65644782/how-to-install-pip-for-python-3-9-on-ubuntu-20-04
RUN apt install -y python${PYTHON_VERSION}-distutils
RUN cd /home/tmp/ && python get-pip.py

RUN cd /home/${_CFG__DEPLOYABLE} && pip install ${_CFG__DEPLOYABLE}-${_CFG__DEPLOYABLE_VERSION}-py3-none-any.whl

# As explained in https://devopscube.com/keep-docker-container-running/, to ensure that the build server keeps running
# after running build script, in case that we want to debug it, we must have an entrypoint.
#
ENTRYPOINT ["tail", "-f", "/dev/null"]