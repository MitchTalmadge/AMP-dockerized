#!/bin/bash -e
set +o xtrace

# Create user and group that will own the config files (if they don't exist already).
echo "Ensuring AMP user exists..."
if [ ! "$(getent group ${GID})" ]; then
  # Create group
  addgroup \
  --gid ${GID} \
  amp
fi
APP_GROUP=$(getent group ${GID} | awk -F ":" '{ print $1 }')
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
APP_USER=$(getent passwd ${UID} | awk -F ":" '{ print $1 }')

echo "Ensuring correct file permissions..."
chown -R ${APP_USER}:${APP_GROUP} /home/amp

# Update the instance manager.
echo "Checking for ampinstmgr updates..."
/bin/bash /opt/entrypoint/update-ampinstmgr.sh

# Create Main Instance if not exists
if [ ! $(su ${APP_USER} --command "ampinstmgr ShowInstancesList" | grep "Instance Name" | awk '{ print $4 }' | grep "Main") ]; then
  echo "Creating Main Instance... (This can take a while)"
  su ${APP_USER} --command "ampinstmgr CreateInstance \"${MODULE}\" Main 0.0.0.0 \"${PORT}\" \"${LICENCE}\" \"${USERNAME}\" \"${PASSWORD}\"" | grep --line-buffered -v -E '\[[-#]+\]'
fi

# Set instances to MainLine or Nightly
if [ ! -z "$NIGHTLY" ]; then
  # Nightly
  echo "Setting all instances to use Nightly updates..."
  su ${APP_USER} --command "ampinstmgr ShowInstancesList" | grep "Instance Name" | awk '{ print $4 }' | while read -r INSTANCE_NAME; do
    echo "> ${INSTANCE_NAME}:"
    su ${APP_USER} --command "ampinstmgr Switch \"${INSTANCE_NAME}\" Nightly" | grep --line-buffered -v -E '\[[-#]+\]'
  done
else
  # MainLine
  echo "Setting all instances to use MainLine updates..."
  su ${APP_USER} --command "ampinstmgr ShowInstancesList" | grep "Instance Name" | awk '{ print $4 }' | while read -r INSTANCE_NAME; do
    echo "> ${INSTANCE_NAME}:"
    su ${APP_USER} --command "ampinstmgr Switch \"${INSTANCE_NAME}\" MainLine True" | grep --line-buffered -v -E '\[[-#]+\]'
  done
fi

# Upgrade instances
echo "Upgrading Instances... (This can take a while)"
su ${APP_USER} --command "ampinstmgr UpgradeAll" | grep --line-buffered -v -E '\[[-#]+\]'

# Set Main instance to start on boot if not already.
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
tail -f /dev/null &
wait $!
