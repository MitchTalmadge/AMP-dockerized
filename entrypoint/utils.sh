#!/bin/bash
consume_progress_bars() {
  # See https://github.com/MitchTalmadge/AMP-dockerized/issues/25#issuecomment-670251321
  grep --line-buffered -v -E '\[[-#]+\]'
}

does_main_instance_exist() {
  run_amp_command "ShowInstancesList" | grep "Instance Name" | awk '{ print $4 }' | grep -q "Main"
}

run_amp_command() {
  su ${APP_USER} --command "ampinstmgr $1"
}