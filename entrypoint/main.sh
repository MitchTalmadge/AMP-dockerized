#!/usr/bin/env bash
set -Eeuo pipefail

DATA_ROOT=/opt/cubecoders/amp3/data
BOOTSTRAP_STATE=/var/lib/amp3-docker
ENV_FILE=/etc/amp3-docker.env

PORT=${PORT:-8443}
AMP3_STREAM=${AMP3_STREAM:-preview}
AMP3_LANG=${AMP3_LANG:-en}
AMP3_REPO=${AMP3_REPO:-https://cdn-repo.c7rs.com/amp3}
AMP3_ORIGIN=${AMP3_ORIGIN:-https://cdn-downloads.c7rs.com/AMP3}
TZ=${TZ:-Etc/UTC}

fail() {
  printf 'AMP 3 container startup error: %s\n' "$1" >&2
  exit 1
}

valid_url() {
  [[ $1 =~ ^https?://([A-Za-z0-9.-]+|\[[0-9A-Fa-f:.]+\])(:[0-9]{1,5})?(/[A-Za-z0-9._~%/+-]*)?$ ]]
}

[[ $PORT =~ ^[0-9]{1,5}$ ]] || fail "PORT must be a number from 1 to 65535."
(( 10#$PORT >= 1 && 10#$PORT <= 65535 )) || fail "PORT must be a number from 1 to 65535."

case "$AMP3_STREAM" in
  mainline|preview|development) ;;
  *) fail "AMP3_STREAM must be mainline, preview, or development." ;;
esac

case "$AMP3_LANG" in
  en|de|fr|nl) ;;
  *) fail "AMP3_LANG must be en, de, fr, or nl." ;;
esac

valid_url "$AMP3_REPO" || fail "AMP3_REPO must be an http(s) URL using letters, digits, dots, slashes, and URL-safe punctuation."
valid_url "$AMP3_ORIGIN" || fail "AMP3_ORIGIN must be an http(s) URL using letters, digits, dots, slashes, and URL-safe punctuation."

case "$TZ" in
  ''|/*|*..*|*\\*) fail "TZ must be a zoneinfo name such as Etc/UTC or America/Denver." ;;
esac
[ -f "/usr/share/zoneinfo/$TZ" ] || fail "Timezone '$TZ' was not found in the zoneinfo database."

mkdir -p "$DATA_ROOT" "$BOOTSTRAP_STATE" /etc
chmod 0755 "$DATA_ROOT"
ln -snf "/usr/share/zoneinfo/$TZ" /etc/localtime
printf '%s\n' "$TZ" >/etc/timezone

# Keep the container's machine identity stable across restarts and container
# replacements that reuse the AMP 3 data volume.
MACHINE_ID_FILE="$DATA_ROOT/.docker-machine-id"
if [ -s "$MACHINE_ID_FILE" ]; then
  MACHINE_ID=$(tr -d '[:space:]' <"$MACHINE_ID_FILE")
  [[ $MACHINE_ID =~ ^[0-9a-fA-F]{32}$ ]] || fail "Stored machine ID at $MACHINE_ID_FILE is invalid."
  printf '%s\n' "$MACHINE_ID" >/etc/machine-id
else
  rm -f /etc/machine-id
  systemd-machine-id-setup
  MACHINE_ID=$(tr -d '[:space:]' </etc/machine-id)
  [[ $MACHINE_ID =~ ^[0-9a-fA-F]{32}$ ]] || fail "Could not create a persistent machine ID."
  install -m 0444 /etc/machine-id "$MACHINE_ID_FILE"
fi
chmod 0444 /etc/machine-id

# All values written here are validated above; the installer consumes this
# file through systemd's EnvironmentFile support.
cat >"$ENV_FILE" <<EOF
PORT=$PORT
AMP3_STREAM=$AMP3_STREAM
AMP3_LANG=$AMP3_LANG
AMP3_REPO=$AMP3_REPO
AMP3_ORIGIN=$AMP3_ORIGIN
EOF
chmod 0644 "$ENV_FILE"

echo "Starting AMP 3 container services (stream: $AMP3_STREAM, panel port: $PORT)."
exec /sbin/init
