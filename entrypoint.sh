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

# Create Main Instance
if [ ! -d ".ampdata/instances/Main" ]
then
	sudo -u amp ampinstmgr CreateInstance "${MODULE}" Main 0.0.0.0 "${PORT}" "${LICENCE}" "${USERNAME}" "${PASSWORD}"
else
  # Automatic AMP Upgrades
  sudo -u amp ampinstmgr UpgradeAll
fi

# Launch Main Instance
echo "Starting AMP..."
sudo -u amp ampinstmgr StartInstance Main
echo "AMP Started."

# Trap SIGTERM for a graceful shutdown
shutdown() {
  echo "Shutting Down AMP..."
  sudo -u amp ampinstmgr StopAll
  echo "Shutdown Complete."
  exit 0
}
trap "shutdown" SIGTERM

# Sleep
echo "Entrypoint Sleeping. Logs can be viewed through AMP web UI or at ampdata/instances/Main/AMP_Logs"
tail -f /dev/null & wait $!
