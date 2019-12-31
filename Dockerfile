FROM ubuntu:18.04

ENV UID=1000
ENV GID=1000
ENV PORT=8080
ENV USERNAME=admin
ENV PASSWORD=password
ENV LICENCE=notset
ENV MODULE=ADS

# Initialize
RUN apt-get update
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get install -y \
  sudo \
  wget

# Configure Locales
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get install -y locales
RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    locale-gen
ENV LANG en_US.UTF-8  
ENV LANGUAGE en_US:en  
ENV LC_ALL en_US.UTF-8     

# Add Mono apt source
ARG DEBIAN_FRONTEND=noninteractive
RUN apt install -y \
  apt-transport-https \
  dirmngr \
  software-properties-common \
  gnupg \
  ca-certificates
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF
RUN echo "deb https://download.mono-project.com/repo/debian stable-stretch main" | tee /etc/apt/sources.list.d/mono-official-stable.list
RUN apt update

# Install Mono Certificates
ARG DEBIAN_FRONTEND=noninteractive
RUN apt-get install -y ca-certificates-mono
RUN wget -O /tmp/cacert.pem https://curl.haxx.se/ca/cacert.pem
RUN cert-sync /tmp/cacert.pem

# Add CubeCoders apt source
RUN apt-key adv --fetch-keys http://repo.cubecoders.com/archive.key
RUN apt-add-repository "deb http://repo.cubecoders.com/ debian/"
RUN apt update

# Install dependencies for various game servers.
RUN ls -al /usr/local/bin/
ARG DEBIAN_FRONTEND=noninteractive
RUN apt install -y \
  openjdk-8-jre-headless \
  libcurl4 \
  lib32gcc1 \
  lib32stdc++6 \
  lib32tinfo5

# Manually install AMP (Docker doesn't have systemctl and other things that AMP's deb postinst expects).
ARG DEBIAN_FRONTEND=noninteractive
RUN apt install -y \
  tmux \
  wget \
  git \
  socat \
  unzip \
  iputils-ping

RUN mkdir -p /opt/cubecoders/amp
WORKDIR /opt/cubecoders/amp
RUN wget http://cubecoders.com/Downloads/ampinstmgr.zip
RUN unzip ampinstmgr.zip
RUN rm -irf ampinstmgr.zip
RUN ln -s /opt/cubecoders/amp/ampinstmgr /usr/local/bin/ampinstmgr
WORKDIR /

# Set up environment
COPY entrypoint.sh /opt/entrypoint.sh
RUN chmod +x /opt/entrypoint.sh

ENTRYPOINT ["/opt/entrypoint.sh"]
