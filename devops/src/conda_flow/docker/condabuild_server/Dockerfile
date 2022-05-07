ARG UBUNTU_IMAGE
FROM ${UBUNTU_IMAGE}
RUN apt update && apt upgrade -y

# Get GIT
RUN apt install -y git

# Get curl (needed to download Conda)
RUN apt install -y curl

# Get Anaconda. This requires multiple steps. Based on instructions from https://linuxhint.com/install_anaconda_ubuntu/
#
# Step 1: download Anaconda's installer

# GOTChA: Force a removal of the downloaded file if it exists in the cache, since we want to get the right sha256sum
RUN if [ -f /tmp/anaconda.sh ]; then rm /tmp/anaconda.sh; fi

# The website to download Anaconda's installer is something like
#
#        https://repo.anaconda.com/archive/Anaconda3-2021.11-Linux-x86_64.sh
#     
ARG ANACONDA_VERSION                                               
RUN cd /tmp && curl https://repo.anaconda.com/archive/Anaconda3-${ANACONDA_VERSION}.sh --output anaconda.sh


# Step 2: Verify data integrity: the sha256sum on the installer must match the expected hash from
#           https://docs.anaconda.com/anaconda/install/hashes/lin-3-64/
#
#   This requires some text manipulation to compute as string $HASH_FOUND that we can compare about the
#   expected $ANACONDA_SHA that was set in pipeline_definition.sh

#   First: given that the sha256sum command will return something like 
#
#           c7554d41336280bddc6a754c9b6e37e1ea42aad95ad6f80629602c5aec3a7b44 Anaconda3-2021.11-Linux-x86_64.sh
#
#       we pipe it through awk to split it by space delimeter, which causes $1 to be the hash we seek, i.e., 
#       in the example that would be
#
#           c7554d41336280bddc6a754c9b6e37e1ea42aad95ad6f80629602c5aec3a7b44
#   
#   Second, when we compare the hash we found to the hash we expected (i.e., to $ANACONDA_SHA as defined in
#       pipeline_definition.sh), we need to cause this build to fail if the verification fails, so 
#       we use an if statement for that.
#
ARG ANACONDA_SHA
RUN cd /tmp && export HASH_FOUND=$(sha256sum anaconda.sh | awk '{print $1;}') \
        && echo "Expecting:    $ANACONDA_SHA" \
        && echo "Found:        $HASH_FOUND" \
        && if [ "${HASH_FOUND}" = "${ANACONDA_SHA}" ]; \
                then echo "Anaconda installer's hash verification succeeded"; \
                else echo "Anaconda installer's hash verification failed" && exit 1; \
            fi 

# The Anaconda installer will ask questions, so we pipe the answers to it. The questions are:
#  
#   1.In order to continue the installation process, please review the license agreement.
#               Please, press ENTER to continue
#
#   2. Do you accept the license terms? [yes|no]
#   3. Anaconda3 will now be installed into this location: /root/anaconda3
#
#           - Press ENTER to confirm the location
#           - Press CTRL-C to abort the installation
#           - Or specify a different location below
#
#   4. Do you wish the installer to initialize Anaconda3 by running conda init? [yes|no]
#
#   So we pipe answers to these questions as:
#       - '' for question #1 (this like hitting ENTER)
#       - 'yes' for question #2
#       - '/home/anaconda3' for question #3
#       - 'yes' for question #4

RUN cd /tmp &&  printf '%s\n' '' 'yes' '/home/anaconda3' 'yes' | bash anaconda.sh

# GOTCHA: Can't do
#
#           RUN source ~/.bashrc
#
#   because Docker RUN commands run in bin/sh, and 'source' is a command in bin/bash, not in bin/sh.
#   So the workaround is to piple the command to an invocation of bash
#
RUN echo "source ~/.bashrc" | /bin/bash

# Step 4: Verify that Anaconda installed properly and it's in the $PATH. 
#
RUN /home/anaconda3/bin/conda info

# As explained in https://devopscube.com/keep-docker-container-running/, to ensure that the build server keeps running
# after running build script, in case that we want to debug it, we must have an entrypoint:
#
ENTRYPOINT ["tail", "-f", "/dev/null"]




