#!/bin/bash

check_data_volume() {
  # Starting with V24, we recommend that users mount /home/amp instead of /home/amp/.ampdata. 
  # This function allows existing users to simply change their mount point in the container, 
  # without needing to do any complicated remapping of their host data.
  echo "Checking data volume..."

  local AMP_HOME="/home/amp"
  local AMP_DATA_DIR="${AMP_HOME}/.ampdata"
  local AMP_DOCKERIZED_DIR="${AMP_DATA_DIR}/.amp-dockerized"
  local LEGACY_INSTANCES_JSON="${AMP_HOME}/instances.json"
  local LEGACY_INSTANCES_DIR="${AMP_HOME}/instances"

  if [ -f "${LEGACY_INSTANCES_JSON}" ] || [ -d "${LEGACY_INSTANCES_DIR}" ]; then
    echo "Updated data volume detected. Migration is required."
    # At this point we have detected that the contents of .ampdata are mapped to /home/amp, which is expected for V24 volume migration.
    # For example, the volume mount may have changed from:
    #     /mnt/user/appdata/amp:/home/amp/.ampdata 
    # to...
    #     /mnt/user/appdata/amp:/home/amp
    if [ -d "${AMP_DATA_DIR}" ]; then # This can happen if the new volume (/home/amp) was accidentally mounted on image v23 or earlier.
      if [ ! -z "$(ls -A "${AMP_DATA_DIR}")" ]; then # Something is very odd if .ampdata is not empty.
        echo "Error: Need to migrate data (${LEGACY_INSTANCES_DIR} and ${LEGACY_INSTANCES_JSON}), but ${AMP_DATA_DIR} is not empty. Please resolve this conflict manually. For help, visit https://github.com/MitchTalmadge/AMP-dockerized/discussions/247"
        exit 1
      fi
      echo "Empty .ampdata directory detected. Removing..."
      rmdir "${AMP_DATA_DIR}"
    fi
    
    echo "Beginning data migration..."
    mkdir -p "${AMP_DATA_DIR}"

    find "${AMP_HOME}" -mindepth 1 -maxdepth 1 \
      ! -name '.ampdata' \
      ! -name 'scripts' \
      -exec mv {} "${AMP_DATA_DIR}" \;

    # For future use, we will leave a fingerprint indicating that a migration took place
    mkdir -p "${AMP_DOCKERIZED_DIR}"
    touch "${AMP_DOCKERIZED_DIR}/.v24_volume_migrated"

    echo "Migration complete."
  fi

  echo "Data volume is ok!"
}

# Configure file permissions
check_file_permissions() {
  echo "Checking file permissions..."
  chown -R ${APP_USER}:${APP_GROUP} /home/amp
  if [ -w /home/amp ]; then
    echo "File permissions set for ${APP_USER}:${APP_GROUP}. Directory /home/amp is writable."
  else
    echo "Warning: Directory /home/amp is not writable for ${APP_USER}:${APP_GROUP}."
    # Attempt to align permissions if ownership alone is insufficient
    chmod 755 /home/amp
    if [ -w /home/amp ]; then
      echo "Permissions updated. Directory /home/amp is now writable for ${APP_USER}:${APP_GROUP}."
    else
      echo "Warning: Directory /home/amp remains non-writable for ${APP_USER}:${APP_GROUP}."
    fi
  fi
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

  local main_name
  main_name=$(get_main_instance_name)

  echo "Setting ADS instance to start on boot..."
  run_amp_command "ShowInstanceInfo ${main_name}" | grep "Start on Boot" | grep -q "No" && run_amp_command "SetStartBoot ${main_name} yes" || true
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

create_group_user() {
  local AMP_GID="${GID}"
  local GROUP_GID="${DOCKER_GID}"
  local DOCKER_DESKTOP=""
  # Try to detect docker socket GID
  if [ -z "${GROUP_GID}" ] && [ -S "/var/run/docker.sock" ]; then
    GROUP_GID=$(stat -c '%g' /var/run/docker.sock)
    if [ "${GROUP_GID}" = "0" ]; then
      echo "Docker socket owned by root group. Not using docker group."
      GROUP_GID=""
    else
      echo "Detected docker socket GID: ${GROUP_GID}"
    fi
  # try to detect Docker Desktop remote API via DOCKER_HOST
  elif [ -z "${GROUP_GID}" ] && [ -n "${DOCKER_HOST}" ]; then
    if echo "${DOCKER_HOST}" | grep -qi '^tcp://host\.docker\.internal:2375'; then
      echo "Docker Desktop remote host detected via DOCKER_HOST."
      DOCKER_DESKTOP="1"
    else
      echo "DOCKER_HOST is set but does not appear to be Docker Desktop remote API."
    fi
  else
    echo "docker socket and DOCKER_HOST not found. Using default AMP GID: ${AMP_GID}"
  fi

  # Docker group detected
  if getent group docker > /dev/null 2>&1; then
    APP_GROUP=docker
    export APP_GROUP
  # Docker Desktop remote API detected
  elif [ "${DOCKER_DESKTOP}" = "1" ]; then
    if ! getent group docker > /dev/null 2>&1; then
      echo "Creating docker group for Docker Desktop remote API..."
      addgroup --system docker
    fi
    APP_GROUP=docker
    export APP_GROUP

  # GROUP_GID is available
  elif [ -n "${GROUP_GID}" ]; then
    if ! getent group ${GROUP_GID} > /dev/null 2>&1; then
      echo "Creating docker group with GID ${GROUP_GID}..."
      addgroup --gid ${GROUP_GID} docker
    fi
    APP_GROUP=docker
    export APP_GROUP

  # AMP_GID is used
  else
    if ! getent group ${AMP_GID} > /dev/null 2>&1; then
      echo "Creating AMP group with GID ${AMP_GID}..."
      addgroup --gid ${AMP_GID} amp
    fi
    APP_GROUP=amp
    export APP_GROUP
  fi
  APP_GID=$(getent group ${APP_GROUP} | awk -F ":" '{ print $3 }')
  echo "Group Created: ${APP_GROUP} (${APP_GID})"
}

# AMP user/group
create_amp_user() {
  # Create AMP user
  echo "Creating AMP user..."
  if ! getent passwd ${UID} > /dev/null 2>&1; then
    adduser --uid ${UID} --shell /bin/bash --no-create-home --disabled-password --gecos "" --ingroup ${APP_GROUP} amp
    deluser amp users 2>/dev/null || true
  fi
  APP_USER=$(getent passwd ${UID} | awk -F ":" '{ print $1 }')
  echo "User Created: ${APP_USER} (${UID})"

  # Verify user details
  echo "Verifying ${APP_USER} user details..."
  echo "$(id ${APP_USER})"
}

# AMP user/group
create_amp_user() {
  # Create AMP user
  echo "Creating AMP user..."
  if ! getent passwd ${UID} > /dev/null 2>&1; then
    adduser --uid ${UID} --shell /bin/bash --no-create-home --disabled-password --gecos "" --ingroup ${APP_GROUP} amp
    deluser amp users 2>/dev/null || true
  fi
  APP_USER=$(getent passwd ${UID} | awk -F ":" '{ print $1 }')
  echo "User Created: ${APP_USER} (${UID})"

  # Verify user details
  echo "Verifying AMP user details..."
  echo "$(id ${APP_USER})"
}

# Reactivates the AMP licence across all instances
configure_license() {
  if [ -n "${AMP_LICENCE}" ]; then
    echo "Reactivating AMP licence across instances."
    if run_amp_command_silently "ReactivateAll \"${AMP_LICENCE}\"" >/dev/null 2>&1; then
      echo "Licence reactivated successfully."
    else
      echo "Warning: Failed to reactivate licence."
    fi

    # Reactivate ADS01 specifically
    echo "Reactivating ADS01."
    if run_amp_command_silently "Reactivate ADS01 \"${AMP_LICENCE}\"" >/dev/null 2>&1; then
      echo "ADS01 reactivated successfully."
    else
      echo "Warning: Failed to reactivate ADS01."
    fi
  fi
}

# Detects and sets AMP_HOST_HOME environment variable
amp_host_home() {
  # If AMP_HOST_HOME is already set externally, do nothing.
  if [ -n "${AMP_HOST_HOME}" ]; then
    return
  fi
  # Ensure Docker CLI is available
  if command -v docker >/dev/null 2>&1; then
    # Try to detect the host directory via docker inspect
    local docker_name=""
    local docker_mount=""
    docker_name=$(docker ps --filter "volume=/home/amp" --format "{{.Names}}")
    docker_mount=$(docker inspect "$docker_name" --format '{{range .Mounts}}{{if eq .Destination "/home/amp"}}{{.Source}}{{end}}{{end}}' 2>/dev/null || true)
    if [ -n "$docker_mount" ]; then
      AMP_HOST_HOME="$docker_mount"
      export AMP_HOST_HOME
    else
      echo "Warning: docker inspect did not return a mount source for $docker_name"
    fi
  fi
  # Report the detected host directory
  if [ -n "${AMP_HOST_HOME}" ]; then
    echo "AMP data mount source: ${AMP_HOST_HOME}"
  else
    echo "AMP data mount source: unknown"
  fi
}

# Handles errors during startup
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

# Monitors AMP for pending tasks
monitor_amp() {
  # Periodically process pending tasks (e.g. upgrade, reboots, ...)
  while true; do
    run_amp_command_silently "ProcessPendingTasks"
    sleep 60 # Check for pending tasks every 60 seconds to reduce CPU usage
  done
}

# Runs user-provided startup script
run_startup_script() {
  # Users may provide their own startup script for installing dependencies, etc.
  STARTUP_SCRIPT="/home/amp/scripts/startup.sh"
  if [ -f ${STARTUP_SCRIPT} ]; then
    echo "Running startup script..."
    chmod +x ${STARTUP_SCRIPT}
    /bin/bash ${STARTUP_SCRIPT}
  fi
}

# Shuts down AMP
shutdown() {
  echo "Shutting down... (Signal ${1})"
  if [ -n "${AMP_STARTED}" ] && [ "${AMP_STARTED}" -eq 1 ] && [ "${1}" != "KILL" ]; then
    stop_amp
  fi
  exit 0
}

# Starts AMP
start_amp() {
  echo "Starting AMP..."
  run_amp_command "StartBoot"
  export AMP_STARTED=1
  echo "AMP Started!"
}

# Stops AMP
stop_amp() {
  echo "Stopping AMP..."
  run_amp_command "StopAll"
  echo "AMP Stopped."
}

# Upgrades all instances
upgrade_instances() {
  echo "Upgrading instances..."
  run_amp_command "UpgradeAll" | consume_progress_bars
}