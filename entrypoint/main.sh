#!/bin/bash -e
set +o xtrace

echo "----------------------"
echo "Starting AMP-Dockerized..."
echo "----------------------"
echo "Note: This is an UNOFFICIAL IMAGE for CubeCoders AMP. This was created by the community, NOT CubeCoders."
echo "Please, DO NOT contact CubeCoders (Discord or otherwise) for technical support when using this image."
echo "They do not support nor endorse this image and will not help you."
echo "Instead, please direct support requests to https://github.com/MitchTalmadge/AMP-dockerized/issues."
echo "Thank you!!"
echo "----------------------"
echo ""

# Migrate legacy vars
export AMP_LICENCE=${AMP_LICENCE:-${LICENCE:-"notset"}}}
export AMP_MODULE=${AMP_MODULE:-${MODULE:-"ADS"}}

# Users may provide their own startup script for installing dependencies, etc.
STARTUP_SCRIPT="/home/amp/scripts/startup.sh"
if [ -f ${STARTUP_SCRIPT} ]; then
  echo "Running startup script..."
  chmod +x ${STARTUP_SCRIPT}
  /bin/bash ${STARTUP_SCRIPT}
fi

echo "Creating AMP user..."
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

echo "Checking file permissions..."
chown -R ${APP_USER}:${APP_GROUP} /home/amp

echo "Configuring timezone..."
ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ >/etc/timezone
dpkg-reconfigure --frontend noninteractive tzdata

echo "Checking licence..."
if [ ${AMP_LICENCE} = "notset" ]; then
  echo "Error: AMP_LICENCE is not set. You need to have a valid AMP licence from cubecoders.com specified in the AMP_LICENCE environment variable"
  exit 1
fi

echo "Checking Main instance..."
if [ ! $(su ${APP_USER} --command "ampinstmgr ShowInstancesList" | grep "Instance Name" | awk '{ print $4 }' | grep "Main") ]; then
  echo "Creating Main instance... (This can take a while)"
  su ${APP_USER} --command "ampinstmgr CreateInstance \"${AMP_MODULE}\" Main \"${IPBINDING}\" \"${PORT}\" \"${AMP_LICENCE}\" \"${USERNAME}\" \"${PASSWORD}\"" | grep --line-buffered -v -E '\[[-#]+\]'
fi

echo "Setting release stream to ${AMP_RELEASE_STREAM}..."
su ${APP_USER} --command "ampinstmgr ShowInstancesList" | grep "Instance Name" | awk '{ print $4 }' | while read -r INSTANCE_NAME; do
  echo "> ${INSTANCE_NAME}:"
  su ${APP_USER} --command "ampinstmgr ChangeInstanceStream \"${INSTANCE_NAME}\" ${AMP_RELEASE_STREAM} True" | grep --line-buffered -v -E '\[[-#]+\]'
done

if [ ${AMP_AUTO_UPDATE} = "true" ]; then
  echo "Auto-updating instances..."
  su ${APP_USER} --command "ampinstmgr UpgradeAll" | grep --line-buffered -v -E '\[[-#]+\]'
else
  echo "Skipping automatic updates."
fi

echo "Setting Main instance to start on boot..."
su ${APP_USER} --command "ampinstmgr ShowInstanceInfo Main | grep \"Start on Boot\" | grep \"No\" && ampinstmgr SetStartBoot Main yes || true" 

echo "Starting AMP..."
su ${APP_USER} --command "ampinstmgr StartBoot"
echo "AMP Started!"

# Trap SIGTERM for a graceful shutdown
shutdown() {
  echo "Shutting Down AMP..."
  su ${APP_USER} --command "ampinstmgr StopAll"
  echo "Shutdown Complete."
  exit 0
}
trap "shutdown" SIGTERM

# Sleep
echo "AMP is now running. Logs can be viewed through AMP web UI or at ampdata/instances/Main/AMP_Logs"
tail -f /dev/null &
wait $!
