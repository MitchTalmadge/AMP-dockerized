#!/bin/bash -e
set +o xtrace

echo "----------------------"
echo "Starting AMP-Dockerized..."
echo "----------------------"
echo "Note: This is an UNOFFICIAL IMAGE for CubeCoders AMP. This was created by the community, NOT CubeCoders."
echo "Please, DO NOT contact CubeCoders (Discord or otherwise) for technical support when using this image."
echo "They do not support nor endorse this image and will not help you."
echo "Instead, please direct support requests to https://github.com/MitchTalmadge/AMP-dockerized/issues."
echo "We are happy to help you there!"
echo "Thank you!!"
echo "----------------------"
echo ""

# Copy the pre-cached AMP Core from the image into the location AMP expects.
# This will allow upgrades to use the cache and not need to do any downloads.
echo "Copying AMP Core..."
mkdir -p /home/amp/.ampdata/instances/
cp /opt/AMPCache* /home/amp/.ampdata/instances/

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

# Let all volume data be owned by the new user.
echo "Ensuring correct file permissions..."
chown -R ${APP_USER}:${APP_GROUP} /home/amp

# Set Timezone
echo "Setting timezone from TZ env var..."
ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ >/etc/timezone
dpkg-reconfigure --frontend noninteractive tzdata

# Ensure a Licence was set
if [ ${LICENCE} = "notset" ]; then
  echo "Error: no Licence specified. You need to have a valid AMP licence from cubecoders.com specified in the LICENCE environment variable"
  exit 1
fi

# Create Main Instance if not exists
echo "Making sure Main instance exists..."
if [ ! $(su ${APP_USER} --command "ampinstmgr ShowInstancesList" | grep "Instance Name" | awk '{ print $4 }' | grep "Main") ]; then
  echo "Creating Main instance... (This can take a while)"
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
echo "Upgrading Instances..."
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

# Java 11 Notice
echo "----------------------"
echo "NOTICE: Java 11 is the new default in this image. If you require Java 8 (e.g. for old Minecraft servers), you may select it through the Java Configuration section in the AMP Web UI. Otherwise, Java 11 will be used automatically."
echo "----------------------"

# Sleep
echo "Entrypoint Sleeping. Logs can be viewed through AMP web UI or at ampdata/instances/Main/AMP_Logs"
tail -f /dev/null &
wait $!
