#!/bin/bash -e
set -o xtrace

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
	su amp --command "ampinstmgr CreateInstance \"${MODULE}\" Main 0.0.0.0 \"${PORT}\" \"${LICENCE}\" \"${USERNAME}\" \"${PASSWORD}\""
else
  # Automatic AMP Upgrades
  su amp --command "ampinstmgr UpgradeAll"
fi

# Launch Main Instance
echo "Starting AMP..."
su amp --command "ampinstmgr SetStartBoot Main"
su amp --command "ampinstmgr StartBoot"
echo "AMP Started."

# Trap SIGTERM for a graceful shutdown
shutdown() {
  echo "Shutting Down AMP..."
  su amp --command "ampinstmgr StopAll"
  echo "Shutdown Complete."
  exit 0
}
trap "shutdown" SIGTERM

# Sleep
echo "Entrypoint Sleeping. Logs can be viewed through AMP web UI or at ampdata/instances/Main/AMP_Logs"
tail -f /dev/null & wait $!
