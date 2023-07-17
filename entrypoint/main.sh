#!/bin/bash -e
#set -o xtrace
set -e

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

source /opt/entrypoint/utils.sh
source /opt/entrypoint/routines.sh
trap 'handle_error' ERR

# Migrate legacy vars
export AMP_LICENCE=${LICENCE:-${AMP_LICENCE:-"notset"}}
export AMP_MODULE=${MODULE:-${AMP_MODULE:-"ADS"}}
if [ ! -z "${NIGHTLY}" ]; then
  export AMP_RELEASE_STREAM="Development"
fi

run_startup_script

create_amp_user

check_licence

configure_timezone

check_file_permissions

configure_main_instance

configure_release_stream

if [ ${AMP_AUTO_UPDATE} = "true" ]; then
  upgrade_instances
else
  echo "Skipping automatic updates."
fi

start_amp
# Trap SIGTERM for a graceful shutdown
trap "stop_amp" SIGTERM

# Sleep
echo "AMP is now running. Logs can be viewed through AMP web UI or at ampdata/instances/Main/AMP_Logs"
tail -f /dev/null &
wait $!
