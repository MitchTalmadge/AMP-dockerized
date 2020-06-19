#!/bin/bash -e
set +o xtrace

# Create user and group that will own the config files (if they don't exist already).
if [ ! "$(getent group ${GID})" ]; then
  # Create group
	addgroup \
		--gid ${GID} \
		amp
fi
APP_GROUP=`getent group ${GID} | awk -F ":" '{ print $1 }'`
if [ ! "$(getent passwd ${UID})" ]; then
  # Create user
  adduser \
		--uid ${UID} \
		--shell /bin/bash \
		--no-create-home \
		--ingroup ${APP_GROUP} \
    --system \
		amp
fi
APP_USER=`getent passwd ${UID} | awk -F ":" '{ print $1 }'`
chown -R ${APP_USER}:${APP_GROUP} /home/amp

# Set up environment
cd /home/amp

# Create Main Instance
if [ ! -d ".ampdata/instances/Main" ]
then
	su ${APP_USER} --command "ampinstmgr CreateInstance \"${MODULE}\" Main 0.0.0.0 \"${PORT}\" \"${LICENCE}\" \"${USERNAME}\" \"${PASSWORD}\""
else
  # Automatic AMP Upgrades
  su ${APP_USER} --command "ampinstmgr UpgradeAll"
fi

# Make Main instance start on boot if disabled.
echo "Ensuring Main Instance will Start on Boot..."
su ${APP_USER} --command "ampinstmgr ShowInstanceInfo Main | grep \"Start on Boot\" | grep \"No\" && ampinstmgr SetStartBoot Main || true"

# Startup
echo "Starting AMP..."
su ${APP_USER} --command "ampinstmgr StartBoot"
echo "AMP Started."

# Trap SIGTERM for a graceful shutdown
shutdown() {
  echo "Shutting Down AMP..."
  su ${APP_USER} --command "ampinstmgr StopAll"
  echo "Shutdown Complete."
  exit 0
}
trap "shutdown" SIGTERM

# Sleep
echo "Entrypoint Sleeping. Logs can be viewed through AMP web UI or at ampdata/instances/Main/AMP_Logs"
tail -f /dev/null & wait $!
