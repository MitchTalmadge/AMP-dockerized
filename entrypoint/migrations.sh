#!/bin/bash

# How to add a migration:
# 1. Increment TARGET_VERSION below to the new highest numeric version.
# 2. Add a function named: migration_<version>_<slug>() (slug is descriptive, lowercase, underscores).
# 3. Inside the function, perform required changes then call mark_version <version>.
#
# Notes:
# - Migrations run in ascending numeric order until current_version == TARGET_VERSION.
# - A migration function MUST call mark_version <version> on success to advance.
# - If a migration fails (non-zero exit), script aborts due to set -e in main.sh.

DOCKERIZE_VERSION_FILE="/home/amp/.ampdata/.dockerized-migration-version"
TARGET_VERSION="1"  # Increase when adding new migrations

# ----------------------------
# Migration Functions
# ----------------------------

migration_1_volume_remap() {
  echo "[migration 1] Remapping volume structure..."
  # TODO
}

# ----------------------------
# Framework Helpers
# ----------------------------

migrations_get_current_version() {
  if [ -f "${DOCKERIZE_VERSION_FILE}" ]; then
    cat "${DOCKERIZE_VERSION_FILE}"
  else
    echo "0"
  fi
}

migrations_mark_version() {
  local new_version="$1"
  echo "${new_version}" > "${DOCKERIZE_VERSION_FILE}"
}

migrations_discover_functions() {
  # List declared functions matching migration_<number>_*
  # Output: version functionName
  declare -F | awk '{print $3}' | grep -E '^migration_[0-9]+_' | while read -r fn; do
    local ver_part
    ver_part=$(echo "$fn" | sed -E 's/^migration_([0-9]+)_.*/\1/')
    echo "${ver_part} ${fn}"
  done | sort -n -k1,1
}

migrations_run_all() {
  local current_version
  current_version=$(migrations_get_current_version)
  if [ "${current_version}" -ge "${TARGET_VERSION}" ]; then
    echo "[migration] No migrations needed."
    return 0
  fi

  echo "[migration] Starting migrations: current=${current_version}, target=${TARGET_VERSION}" 

  while [ "${current_version}" -lt "${TARGET_VERSION}" ]; do
    local applied_any="false"
    while read -r ver fn; do
      # Only run migrations for next version step (current_version+1) to ensure ordering/atomicity per version.
      if [ "$ver" -eq $((current_version + 1)) ]; then
        if declare -F "$fn" >/dev/null 2>&1; then
          echo "[migration] Executing $fn (version $ver)"
          "$fn" || { echo "[migration] ERROR: $fn failed" >&2; return 1; }
          applied_any="true"
          break  # After marking version, break to re-evaluate current_version
        fi
      fi
    done < <(migrations_discover_functions)

    current_version=$(migrations_get_current_version)
    if [ "${applied_any}" = "false" ]; then
      echo "[migration] WARNING: No migration function found to advance from version ${current_version}. TARGET_VERSION=${TARGET_VERSION}."
      echo "[migration] Ensure a function named migration_${current_version}_<slug>() exists or adjust TARGET_VERSION." >&2
      return 1
    fi
  done

  echo "[migration] All migrations complete. Current version=$(migrations_get_current_version)"
}