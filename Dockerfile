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
  jq \
  wget && \
  apt-get -y clean && \
	apt-get -y autoremove --purge && \
	rm -rf \
  /tmp/* \
  /var/lib/apt/lists/* \
  /var/tmp/*

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
  ca-certificates && \
  apt-get -y clean && \
	apt-get -y autoremove --purge && \
	rm -rf \
  /tmp/* \
  /var/lib/apt/lists/* \
  /var/tmp/*
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF
RUN echo "deb https://download.mono-project.com/repo/debian stable-stretch main" | tee /etc/apt/sources.list.d/mono-official-stable.list

# Install Mono Certificates
ARG DEBIAN_FRONTEND=noninteractive
RUN apt update && \
    apt-get install -y ca-certificates-mono && \
    apt-get -y clean && \
	  apt-get -y autoremove --purge && \
	  rm -rf \
    /tmp/* \
    /var/lib/apt/lists/* \
    /var/tmp/*
RUN wget -O /tmp/cacert.pem https://curl.haxx.se/ca/cacert.pem
RUN cert-sync /tmp/cacert.pem

# Add CubeCoders apt source
RUN apt-key adv --fetch-keys http://repo.cubecoders.com/archive.key
RUN apt-add-repository "deb http://repo.cubecoders.com/ debian/"

# Install dependencies for various game servers.
RUN ls -al /usr/local/bin/
ARG DEBIAN_FRONTEND=noninteractive
RUN apt update && \
    apt install -y \
    openjdk-8-jre-headless \
    libcurl4 \
    lib32gcc1 \
    lib32stdc++6 \
    lib32tinfo5 && \
    apt-get -y clean && \
	  apt-get -y autoremove --purge && \
	  rm -rf \
    /tmp/* \
    /var/lib/apt/lists/* \
    /var/tmp/*

# Manually install AMP (Docker doesn't have systemctl and other things that AMP's deb postinst expects).
ARG DEBIAN_FRONTEND=noninteractive
RUN apt update && \
    apt install -y \
    tmux \
    wget \
    git \
    socat \
    unzip \
    iputils-ping && \
    apt-get -y clean && \
	  apt-get -y autoremove --purge && \
	  rm -rf \
    /tmp/* \
    /var/lib/apt/lists/* \
    /var/tmp/*

# Create ampinstmgr install directory.
# ampinstmgr will be downloaded later when the image is started for the first time.
RUN mkdir -p /home/amp/.ampdata/bin
RUN ln -s /home/amp/.ampdata/bin/ampinstmgr /usr/local/bin/ampinstmgr

# Set up environment
WORKDIR /home/amp
COPY entrypoint /opt/entrypoint
RUN chmod -R +x /opt/entrypoint

ENTRYPOINT ["/opt/entrypoint/main.sh"]
