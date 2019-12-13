#!/bin/bash -e
set -o xtrace

# Create User
if [ ! `getent group amp` ]
then
	groupadd \
		--gid "${GID}" \
		-r \
		amp
	useradd \
		--uid "${UID}" \
		--gid "${GID}" \
		--no-log-init \
		--shell /bin/bash \
		-r \
		-m \
		amp
fi

# Set up environment
cd /home/amp
ln -s /ampdata .ampdata

# Create ADS
if [ ! -d "./ampdata/instances/ADSMain" ] 
then
	sudo -u amp ampinstmgr CreateInstance ADS ADSMain 0.0.0.0 ${PORT} "${LICENCE}" "${USERNAME}" "${PASSWORD}"
fi

# Launch ADS
(cd .ampdata/instances/ADSMain && exec sudo -u amp ./AMP_Linux_x86_64)
