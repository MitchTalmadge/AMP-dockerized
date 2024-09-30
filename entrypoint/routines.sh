#!/bin/bash

check_file_permissions() {
  echo "Checking file permissions..."
  chown -R ${APP_USER}:${APP_GROUP} /home/amp
}

check_licence() {
  echo "Checking licence..."
  if [ ${AMP_LICENCE} = "notset" ]; then
    handle_error "AMP_LICENCE is not set. You need to have a valid AMP licence from cubecoders.com specified in the AMP_LICENCE environment variable"
  fi
  # TODO: Find a way to test the licence validity
}

configure_main_instance() {
  echo "Checking Main instance existence..."
  if ! does_main_instance_exist; then
    echo "Creating Main instance... (This can take a while)"
    run_amp_command "CreateInstance \"${AMP_MODULE}\" Main \"${IPBINDING}\" \"${PORT}\" \"${AMP_LICENCE}\" \"${USERNAME}\" \"${PASSWORD}\"" | consume_progress_bars
    if ! does_main_instance_exist; then
      handle_error "Failed to create Main instance. Please check your configuration."
    fi
  fi

  echo "Setting Main instance to start on boot..."
  run_amp_command "ShowInstanceInfo Main" | grep "Start on Boot" | grep -q "No" && run_amp_command "SetStartBoot Main yes" || true 
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
    sleep 5 # The UI's restart timeout is 10 seconds, so let's be safe.
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

setup_template() {
  [ "$MODULE" == "Generic" ] && [ -n "$AMP_TEMPLATE" ] || return 1

  # Dockerfolder containing instances
  AMP_FOLDER="${AMP_FOLDER:-/home/amp/.ampdata/instances}"

  # AMP's template repo details, note if you're not logged into github you'll eventually hit a rate limit.. be aware of this (I probably should add a check for that)
  AMP_TEMPLATEREPO_OWNER="${AMP_TEMPLATEREPO_OWNER:-CubeCoders}"
  AMP_TEMPLATEREPO_REPO="${AMP_TEMPLATEREPO_REPO:-AMPTemplates}"
  AMP_TEMPLATEREPO_REF="${AMP_TEMPLATEREPO_REF:-HEAD}"

  amptemplate="${AMP_TEMPLATE%.*}"

  # Not needed to touch these variables (unless you know what you're doing)
  if [ -z "${EXCLUDED_KVP+x}" ]; then
    EXCLUDED_KVP=('AnalyticsPlugin.kvp' 'EmailSenderPlugin.kvp' 'FileManagerPlugin.kvp' 'GenericModule.kvp' 'LocalFileBackupPlugin.kvp' 'RCONPlugin.kvp' 'WebRequestPlugin.kvp' 'steamcmdplugin.kvp')
  fi

  if [ -z "${REQUIRED_FILES+x}" ]; then
    REQUIRED_FILES=('${amptemplate}.kvp' '${amptemplate}config.json' '${amptemplate}metaconfig.json')
  fi

  # TODO: move var processing to function

  pushd "$(find $AMP_FOLDER -maxdepth 1 -name "*" -type d | awk 'NR==2')"
  download_templates

  create_merged_template

  apply_template_to_instance
  popd
}

download_templates() {
  # Download templates
  # change directory to the first subfolder of AMP (docker version should only have 1)
  [[ " ${EXCLUDED_KVP[*]} " =~ [[:space:]]${amptemplate}.kvp[[:space:]] ]] && { echo "Trying to install the template ${amptemplate}, but this one of the core templates."; exit 1; }
  for required_file in "${REQUIRED_FILES[@]}"; do
      eval "curr_file=\"$required_file\""
      get_from_github ${curr_file}
      [ ! -f $curr_file ] && { echo "required file: '${curr_file}' not found"; exit 1; }
  done
}

create_merged_template() {
  # create an empty merged kvp
  touch ${amptemplate}_merged.kvp
  while IFS="=" read key value rest; do
      if [ -n "$rest" ]; then
          value="$value=$rest"
      fi
      if [[ $value =~ @IncludeJson\[([^\]]+)\] ]]; then
          jsonfile="${BASH_REMATCH[1]}"
          get_from_github ${jsonfile}
          [ ! -f $jsonfile ] && { echo "required file: '${jsonfile}' not found"; exit 1; }
          value="$(jq -c '.' $jsonfile)"
      fi
      echo "$key=$value" >> ${amptemplate}_merged.kvp
  done < "${amptemplate}.kvp"
  chown ${APP_USER}:${APP_GROUP} ${amptemplate}_merged.kvp
}

apply_template_to_instance() {
  # backup old GenericModule if it's not already done
  [[ -L ./GenericModule.kvp ]] && rm ./GenericModule.kvp
  [ -f ./GenericModule.kvp ] && mv ./GenericModule.kvp ./GenericModule_${amptemplate}_bak.kvp
  # symbolic link the merged template
  su ${APP_USER} -c "ln -s ${amptemplate}_merged.kvp GenericModule.kvp"
  [[ -L ./configmanifest.json ]] && rm ./configmanifest.json
  [ -f ./configmanifest.json ] && mv ./configmanifest.json ./configmanifest_${amptemplate}_bak.json
  su ${APP_USER} -c "ln -s ${amptemplate}config.json configmanifest.json"
  [[ -L ./metaconfig.json ]] && rm ./metaconfig.json
  [ -f ./metaconfig.json ] && mv ./metaconfig.json ./metaconfig_${amptemplate}_bak.json
  su ${APP_USER} -c "ln -s ${amptemplate}metaconfig.json metaconfig.json"
}