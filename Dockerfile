FROM debian:stretch

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
  wget \
  sudo

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

# Install AMP with Minecraft and srcds dependencies
ARG DEBIAN_FRONTEND=noninteractive
RUN apt install -y \
  ampinstmgr \
  openjdk-8-jre-headless \
  lib32gcc1 \
  lib32stdc++6 \
  lib32tinfo5

# Set up environment
COPY entrypoint.sh /opt/entrypoint.sh
RUN chmod +x /opt/entrypoint.sh

ENTRYPOINT ["/opt/entrypoint.sh"]
