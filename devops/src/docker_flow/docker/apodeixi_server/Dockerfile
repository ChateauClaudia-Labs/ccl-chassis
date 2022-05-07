ARG UBUNTU_IMAGE
FROM ${UBUNTU_IMAGE}
RUN apt update && apt upgrade -y

ARG APODEIXI_VERSION

COPY ./apodeixi-${APODEIXI_VERSION}-py3-none-any.whl /home/apodeixi/

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

# If we don't want the default UTC time, do this to set the desirable timezone:
#RUN echo "America/Los_Angeles" > /etc/timezone
RUN rm -f /etc/localtime && ln -sf /usr/share/zoneinfo/America/Los_Angeles /etc/localtime

# Get pip - as suggested in https://stackoverflow.com/questions/65644782/how-to-install-pip-for-python-3-9-on-ubuntu-20-04
RUN apt install -y python${PYTHON_VERSION}-distutils
RUN cd /home/tmp/ && python get-pip.py

RUN cd /home/apodeixi && pip install apodeixi-${APODEIXI_VERSION}-py3-none-any.whl

# As explained in https://devopscube.com/keep-docker-container-running/, to ensure that the build server keeps running
# after running build script, in case that we want to debug it, we must have an entrypoint.
#
ENTRYPOINT ["tail", "-f", "/dev/null"]