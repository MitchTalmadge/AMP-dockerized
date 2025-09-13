#!/bin/bash

consume_progress_bars() {
  # See https://github.com/MitchTalmadge/AMP-dockerized/issues/25#issuecomment-670251321
  grep --line-buffered -v -E '\[[-#]+\]'
}

# Returns the main instance name (ADS01 if present, else Main, else null)
get_main_instance_name() {
  local instance_list
  instance_list=$(run_amp_command "ShowInstancesList" | grep "Instance Name" | awk '{ print $4 }')
  if echo "$instance_list" | grep -q "ADS01"; then
    echo "ADS01"
  elif echo "$instance_list" | grep -q "Main"; then
    echo "Main"
  else
    echo "null"
  fi
}

does_main_instance_exist() {
  local main_name
  main_name=$(get_main_instance_name)
  if [ "$main_name" = "null" ]; then
    return 1
  fi
  return 0
}

run_amp_command() {
  su ${APP_USER} --command "ampinstmgr $1"
}

run_amp_command_silently() {
  su ${APP_USER} --command "ampinstmgr --silent $1"
}

trap_with_arg() {
  # Credit https://stackoverflow.com/a/2183063/2364405
  func="$1" ; shift
  for sig ; do
    trap "$func $sig" "$sig"
  done
}
