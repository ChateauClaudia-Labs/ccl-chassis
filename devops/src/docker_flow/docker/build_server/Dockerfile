ARG UBUNTU_IMAGE
FROM ${UBUNTU_IMAGE}
RUN apt update && apt upgrade -y

# Get required software (GIT, Python). 
# Also set a symbolic link for "python" to the python we install (e.g., "python3.9") so that "python" is 
# treated like a Linux command
#
# GOTCHA Install GIT **after** Python, not before. For some weird reason, installing GIT first will cause the Docker
#       build of the image to "fail" because it will prompt a non-interactive user to select a timezone, and the build
#       will then hang.
ARG UBUNTU_PYTHON_PACKAGE
RUN apt install -y ${UBUNTU_PYTHON_PACKAGE}
RUN apt install -y python3-pip
RUN ln -s $(which ${UBUNTU_PYTHON_PACKAGE}) /usr/bin/python
RUN apt install -y git


# As explained in https://devopscube.com/keep-docker-container-running/, to ensure that the build server keeps running
# after running build script, in case that we want to debug it, we must have an entrypoint:
#
ENTRYPOINT ["tail", "-f", "/dev/null"]


