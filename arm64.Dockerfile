FROM --platform=linux/arm64 ubuntu:20.04

# Set to false to skip downloading the AMP cache which is used for faster upgrades.
ARG CACHE_AMP_UPGRADE=true

ENV UID=1000
ENV GID=1000
ENV TZ=Etc/UTC
ENV PORT=8080
ENV USERNAME=admin
ENV PASSWORD=password
ENV LICENCE=notset
ENV MODULE=ADS

ENV AMP_SUPPORT_LEVEL=UNSUPPORTED
ENV AMP_SUPPORT_TOKEN=AST0/MTAD
ENV AMP_SUPPORT_TAGS="nosupport docker community unofficial unraid"
ENV AMP_SUPPORT_URL="https://github.com/MitchTalmadge/AMP-dockerized/"

ARG DEBIAN_FRONTEND=noninteractive

# Initialize
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    jq \
    sed \
    tzdata \
    wget && \
    apt-get -y clean && \
    apt-get -y autoremove --purge && \
    rm -rf \
    /tmp/* \
    /var/lib/apt/lists/* \
    /var/tmp/*


# Configure Locales
RUN apt-get update && \
    apt-get install -y --no-install-recommends locales && \
    apt-get -y clean && \
    apt-get -y autoremove --purge && \
    rm -rf \
    /tmp/* \
    /var/lib/apt/lists/* \
    /var/tmp/*
RUN sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen && \
    dpkg-reconfigure --frontend=noninteractive locales && \
    update-locale LANG=en_US.UTF-8
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8


# Add Mono apt source
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
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
RUN apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys 3FA7E0328081BFF6A14DA29AA6A19B38D3D831EF && \
    echo "deb https://download.mono-project.com/repo/ubuntu stable-focal main" | tee /etc/apt/sources.list.d/mono-official-stable.list


# Install Mono Certificates
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    ca-certificates-mono && \
    apt-get -y clean && \
    apt-get -y autoremove --purge && \
    rm -rf \
    /tmp/* \
    /var/lib/apt/lists/* \
    /var/tmp/*
RUN wget -O /tmp/cacert.pem https://curl.haxx.se/ca/cacert.pem && \
    cert-sync /tmp/cacert.pem


# Install AMP dependencies
RUN ls -al /usr/local/bin/
RUN dpkg --add-architecture arm64 && \
    apt-get update && \
    apt-get install -y \
    # --------------------
    # Dependencies for AMP:
    tmux \
    git \
    socat \
    unzip \
    iputils-ping \
    procps \
    # --------------------
    # Dependencies for Minecraft:
    openjdk-17-jre-headless \
    openjdk-11-jre-headless \
    openjdk-8-jre-headless \
    # --------------------
    # Dependencies for srcds (TF2, GMod, ...)
    #lib32gcc1 \
    #lib32stdc++6 \
    #lib32z1 \
    #libbz2-1.0:arm64 \
    #libcurl3-gnutls:arm64 \
    #libcurl4 \
    #libncurses5:arm64 \
    #libsdl2-2.0-0 \
    #libsdl2-2.0-0:arm64 \
    #libtinfo5:arm64 \
    # --------------------
    # Dependencies for Factorio:
    xz-utils \
    # --------------------
    && \
    apt-get -y clean && \
    apt-get -y autoremove --purge && \
    rm -rf \
    /tmp/* \
    /var/lib/apt/lists/* \
    /var/tmp/*

# Set Java default
RUN update-alternatives --set java /usr/lib/jvm/java-17-openjdk-arm64/bin/java

# Manually install ampinstmgr by extracting it from the deb package.
# Docker doesn't have systemctl and other things that AMP's deb postinst expects,
# so we can't use apt to install ampinstmgr.
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    software-properties-common \
    dirmngr \
    apt-transport-https && \
    # Add CubeCoders repository and key
    apt-key adv --fetch-keys http://repo.cubecoders.com/archive.key && \
    apt-add-repository "deb http://repo.cubecoders.com/aarch64/ debian/" && \
    apt-get update && \
    # Just download (don't actually install) ampinstmgr
    apt-get install -y --no-install-recommends --download-only ampinstmgr && \
    # Extract ampinstmgr from downloaded package
    mkdir -p /tmp/ampinstmgr && \
    dpkg-deb -x /var/cache/apt/archives/ampinstmgr_*.deb /tmp/ampinstmgr && \
    mv /tmp/ampinstmgr/opt/cubecoders/amp/ampinstmgr /usr/local/bin/ampinstmgr && \
    apt-get -y clean && \
    apt-get -y autoremove --purge && \
    rm -rf \
    /tmp/* \
    /var/lib/apt/lists/* \
    /var/tmp/*

# Get the latest AMP Core to pre-cache upgrades.
RUN if [ "$CACHE_AMP_UPGRADE" = "true" ]; then \
    echo "Pre-caching AMP Upgrade..." && \
    wget https://cubecoders.com/AMPVersions.json -O /tmp/AMPVersions.json && \
    wget https://cubecoders.com/Downloads/AMP_Latest.zip -O /opt/AMPCache-$(cat /tmp/AMPVersions.json | jq -r '.AMPCore' | sed -e 's/\.//g').zip; \
    else echo "Skipping AMP Upgrade Pre-cache."; \
    fi


# Set up environment
COPY entrypoint /opt/entrypoint
RUN chmod -R +x /opt/entrypoint

VOLUME ["/home/amp/.ampdata"]

ENTRYPOINT ["/opt/entrypoint/main.sh"]