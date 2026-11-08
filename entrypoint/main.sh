#!/usr/bin/env bash
set -Eeuo pipefail

ENV_FILE=/etc/amp3-docker.env

PORT=${PORT:-8443}
AMP3_STREAM=${AMP3_STREAM:-preview}
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

valid_url "$AMP3_REPO" || fail "AMP3_REPO must be an http(s) URL using letters, digits, dots, slashes, and URL-safe punctuation."
valid_url "$AMP3_ORIGIN" || fail "AMP3_ORIGIN must be an http(s) URL using letters, digits, dots, slashes, and URL-safe punctuation."

case "$TZ" in
  ''|/*|*..*|*\\*) fail "TZ must be a zoneinfo name such as Etc/UTC or America/Denver." ;;
esac
[ -f "/usr/share/zoneinfo/$TZ" ] || fail "Timezone '$TZ' was not found in the zoneinfo database."

built_stream=$(cat /usr/local/share/amp3-docker/package-stream)
[[ "$AMP3_STREAM" = "$built_stream" ]] || fail "AMP3_STREAM is fixed when the image is built; rebuild for a different stream."
built_repo=$(cat /usr/local/share/amp3-docker/package-repo)
[[ "$AMP3_REPO" = "$built_repo" ]] || fail "AMP3_REPO is fixed when the image is built; rebuild for a different repository."

# Only directory ownership changes run as root; regular data files are initialized
# by the amp account in amp3-bootstrap.service.
python3 /opt/entrypoint/prepare-data.py
ln -snf "/usr/share/zoneinfo/$TZ" /etc/localtime
printf '%s\n' "$TZ" >/etc/timezone

# Validated values are consumed by the unprivileged bootstrap service.
cat >"$ENV_FILE" <<EOF
PORT=$PORT
AMP3_STREAM=$AMP3_STREAM
AMP3_REPO=$AMP3_REPO
AMP3_ORIGIN=$AMP3_ORIGIN
EOF
chmod 0644 "$ENV_FILE"

echo "Starting AMP 3 container services (stream: $AMP3_STREAM, panel port: $PORT)."
exec /sbin/init
