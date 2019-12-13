#!/bin/bash -e

# Create User
if [ ! "$(getent group amp)" ]
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
ln -sfn /ampdata .ampdata

# Create Main Instance
if [ ! -d ".ampdata/instances/Main" ]
then
	sudo -u amp ampinstmgr CreateInstance "${MODULE}" Main 0.0.0.0 "${PORT}" "${LICENCE}" "${USERNAME}" "${PASSWORD}"
else
  # Automatic Licence Reactivation
  #sudo -u amp ampinstmgr Reactivate Main "${LICENCE}"

  # Automatic AMP Upgrades
  sudo -u amp ampinstmgr UpgradeAll
fi

# Launch Main Instance
(cd .ampdata/instances/Main && exec sudo -u amp ./AMP_Linux_x86_64)
