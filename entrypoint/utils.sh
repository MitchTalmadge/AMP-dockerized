#!/bin/bash
consume_progress_bars() {
  # See https://github.com/MitchTalmadge/AMP-dockerized/issues/25#issuecomment-670251321
  grep --line-buffered -v -E '\[[-#]+\]'
}

does_main_instance_exist() {
  run_amp_command "ShowInstancesList" | grep "Instance Name" | awk '{ print $4 }' | grep -q "Main"
}

run_amp_command() {
    # Get the command as a string and the rest as arguments
    local command="$1"
    shift  # Remove the first argument from the list

    # Use an array to handle arguments
    local args=("$@")  # Store all remaining arguments in an array

    # Construct the command
    local cmd="ampinstmgr $command"

    # Append all arguments to the command, quoting them to preserve spaces
    for arg in "${args[@]}"; do
        cmd+=" \"$arg\""  # Quote each argument to preserve any spaces
    done

    # Execute the command with all arguments
    su "${APP_USER}" --command "$cmd"
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

get_from_github() {
  repo_path="$1"
  repo_owner="${2:-${AMP_TEMPLATEREPO_OWNER}}"
  repo_name="${3:-${AMP_TEMPLATEREPO_REPO}}"
  repo_ref="${4:-${AMP_TEMPLATEREPO_REF}}"

  [ ! -n "$repo_path" ] && { echo "No file given, aborting"; return; }

  su ${APP_USER} -c "
    curl \
      -H 'Accept: application/vnd.github.VERSION.raw' \
      https://api.github.com/repos/${repo_owner}/${repo_name}/contents/${repo_path}\?ref\=${repo_ref} -o ${repo_path}
  "
}

safe_link() {
  source_file="$1"
  target_file="${2:-${source_file}}"

  [[ -L ./${target_file} ]] && rm ./${target_file}
  [ -f ./${target_file} ] && mv ./${target_file} ./${target_file}.bak
  # symbolic link the file
  su ${APP_USER} -c "ln -s ${source_file} ${target_file}"
}