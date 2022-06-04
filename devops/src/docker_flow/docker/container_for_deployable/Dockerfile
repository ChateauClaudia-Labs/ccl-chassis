ARG _CFG__APPLICATION_BASE_IMAGE
FROM ${_CFG__APPLICATION_BASE_IMAGE}:latest

ARG _CFG__DEPLOYABLE_VERSION
ARG _CFG__DEPLOYABLE

COPY ./${_CFG__DEPLOYABLE}-${_CFG__DEPLOYABLE_VERSION}-py3-none-any.whl /home/${_CFG__DEPLOYABLE}/

RUN cd /home/${_CFG__DEPLOYABLE} && pip install ${_CFG__DEPLOYABLE}-${_CFG__DEPLOYABLE_VERSION}-py3-none-any.whl

# As explained in https://devopscube.com/keep-docker-container-running/, to ensure that the build server keeps running
# after running build script, in case that we want to debug it, we must have an entrypoint.
#
ENTRYPOINT ["tail", "-f", "/dev/null"]