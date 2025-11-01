#!/bin/bash

check_volume_structure() {
  # Starting with V24, we are asking users to mount /home/amp instead of just /home/amp/.ampdata. 
  # This function allows existing users to simply change their mount point in the container, 
  # without needing to do any complicated remapping of their host data.

  echo "Checking volume structure..."

  local AMP_HOME="/home/amp"
  local AMP_DATA_DIR="${AMP_HOME}/.ampdata"
  local AMP_DOCKERIZED_DIR="${AMP_DATA_DIR}/.amp-dockerized"
  local LEGACY_INSTANCES_JSON="${AMP_HOME}/instances.json"
  local LEGACY_INSTANCES_DIR="${AMP_HOME}/instances"

  if [ -d "${AMP_DATA_DIR}" ]; then
    # There is already a .ampdata directory -- nothing to do.
    echo "Volume structure is valid."
    return 0
  fi

  if [ ! -f "${LEGACY_INSTANCES_JSON}" ] && [ ! -d "${LEGACY_INSTANCES_DIR}" ]; then
    # Neither .ampdata nor the contents of .ampdata exist, so this is a fresh install.
    echo "Volume structure is valid and consistent with fresh install."
    return 0
  fi

  # At this point we have detected that the contents of .ampdata are mapped to /home/amp, which is expected for V24 volume migration.
  # For example, the volume mount may have changed from:
  #     /mnt/user/appdata/amp:/home/amp/.ampdata 
  # to...
  #     /mnt/user/appdata/amp:/home/amp
  echo "Updated volume mount detected. Migrating .ampdata..."
  mkdir -p "${AMP_DATA_DIR}"

  find "${AMP_HOME}" -mindepth 1 -maxdepth 1 \
    ! -name '.ampdata' \
    ! -name 'scripts' \
    -exec mv {} "${AMP_DATA_DIR}" \;

  # Let's also leave a fingerprint indicating that a migration took place
  mkdir -p "${AMP_DOCKERIZED_DIR}"
  touch "${AMP_DOCKERIZED_DIR}/.v24_volume_migrated"

  echo "Migration complete."
}

check_file_permissions() {
  echo "Checking file permissions..."
  chown -R ${APP_USER}:${APP_GROUP} /home/amp
}

configure_main_instance() {
  echo "Checking ADS instance existence..."
  if ! does_main_instance_exist; then
    echo "Creating ADS instance... (This can take a while)"
    run_amp_command "QuickStart \"${USERNAME}\" \"${PASSWORD}\" \"${IPBINDING}\" \"${PORT}\"" | consume_progress_bars
    if ! does_main_instance_exist; then
      handle_error "Failed to create ADS instance. Please check your configuration."
    fi
  fi

  echo "Setting ADS instance to start on boot..."
  run_amp_command "ShowInstanceInfo ADS01" | grep "Start on Boot" | grep -q "No" && run_amp_command "SetStartBoot ADS01 yes" || true
}

configure_release_stream() {
  echo "Setting release stream to ${AMP_RELEASE_STREAM}..."
  # Example Output from ShowInstancesList:
  # [Info] AMP Instance Manager v2.4.5.4 built 26/06/2023 18:20
  # [Info] Stream: Mainline / Release - built by CUBECODERS/buildbot on CCL-DEV
  # Instance ID        │ 295e9fc7-9987-4e4e-94a6-183cb04de459
  # Module             │ ADS
  # Instance Name      │ Main
  # Friendly Name      │ Main
  # URL                │ http://127.0.0.1:8080/
  # Running            │ No
  # Runs in Container  │ No
  # Runs as Shared     │ No
  # Start on Boot      │ Yes
  # AMP Version        │ 2.4.5.4
  # Release Stream     │ Mainline
  # Data Path          │ /home/amp/.ampdata/instances/Main
  run_amp_command "ShowInstancesList" | grep "Instance Name" | awk '{ print $4 }' | while read -r INSTANCE_NAME; do
    local RELEASE_STREAM=$(run_amp_command "ShowInstanceInfo \"${INSTANCE_NAME}\"" | grep "Release Stream" | awk '{ print $4 }')
    if [ "${RELEASE_STREAM}" != "${AMP_RELEASE_STREAM}" ]; then
      echo "Changing release stream of ${INSTANCE_NAME} from ${RELEASE_STREAM} to ${AMP_RELEASE_STREAM}..."
      run_amp_command "ChangeInstanceStream \"${INSTANCE_NAME}\" ${AMP_RELEASE_STREAM} True" | consume_progress_bars
      # Since we changed release streams we have to force an upgrade
      run_amp_command "UpgradeInstance \"${INSTANCE_NAME}\"" | consume_progress_bars
    fi
  done
}

configure_timezone() {
  echo "Configuring timezone..."
  ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ >/etc/timezone
  dpkg-reconfigure --frontend noninteractive tzdata
}

create_amp_user() {
  echo "Creating AMP group..."
  if [ ! "$(getent group ${GID})" ]; then
    # Create group
    addgroup \
    --gid ${GID} \
    amp
  fi
  APP_GROUP=$(getent group ${GID} | awk -F ":" '{ print $1 }')
  echo "Group Created: ${APP_GROUP} (${GID})"

  echo "Creating AMP user..."
  if [ ! "$(getent passwd ${UID})" ]; then
    # Create user
    adduser \
      --uid ${UID} \
      --shell /bin/bash \
      --no-create-home \
      --disabled-password \
      --gecos "" \
      --ingroup ${APP_GROUP} \
      amp
  fi
  APP_USER=$(getent passwd ${UID} | awk -F ":" '{ print $1 }')
  echo "User Created: ${APP_USER} (${UID})"
}

handle_error() {
  # Prints a nice error message and exits.
  # Usage: handle_error "Error message"
  local error_message="$1"
  echo "Sorry! An error occurred during startup and AMP needs to shut down."
  if [ ! -z "${error_message}" ]; then
    echo "Error message: ${error_message}"
  fi
  echo "Please direct any questions or concerns to https://github.com/MitchTalmadge/AMP-dockerized/issues"
  exit 1
}

monitor_amp() {
  # Periodically process pending tasks (e.g. upgrade, reboots, ...)
  while true; do
    run_amp_command_silently "ProcessPendingTasks"
    sleep 60 # Check for pending tasks every 60 seconds to reduce CPU usage
  done
}

run_startup_script() {
  # Users may provide their own startup script for installing dependencies, etc.
  STARTUP_SCRIPT="/home/amp/scripts/startup.sh"
  if [ -f ${STARTUP_SCRIPT} ]; then
    echo "Running startup script..."
    chmod +x ${STARTUP_SCRIPT}
    /bin/bash ${STARTUP_SCRIPT}
  fi
}

shutdown() {
  echo "Shutting down... (Signal ${1})"
  if [ -n "${AMP_STARTED}" ] && [ "${AMP_STARTED}" -eq 1 ] && [ "${1}" != "KILL" ]; then
    stop_amp
  fi
  exit 0
}

start_amp() {
  echo "Starting AMP..."
  run_amp_command "StartBoot"
  export AMP_STARTED=1
  echo "AMP Started!"
}

stop_amp() {
  echo "Stopping AMP..."
  run_amp_command "StopAll"
  echo "AMP Stopped."
}

upgrade_instances() {
  echo "Upgrading instances..."
  run_amp_command "UpgradeAll" | consume_progress_bars
}