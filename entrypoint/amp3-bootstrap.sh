#!/usr/bin/env bash
set -Eeuo pipefail

source /etc/amp3-docker.env

STATE_DIR=/var/lib/amp3-docker
INSTALLED_MARKER="$STATE_DIR/install-complete"

if [ -e "$INSTALLED_MARKER" ]; then
  echo "AMP 3 packages have already been installed in this container."
  exit 0
fi

if [ ! -x /usr/local/sbin/getamp3.sh ]; then
  echo "AMP 3 installer is missing at /usr/local/sbin/getamp3.sh." >&2
  exit 1
fi

mkdir -p "$STATE_DIR"

echo "Installing AMP 3 from the CubeCoders package repository."
echo "The AMP 3 beta currently supports x86_64 containers only."

# --host keeps game server processes in this container, matching the
# all-in-one AMP 3 container model. Users must publish each game port.
/usr/local/sbin/getamp3.sh \
  --yes \
  --lang "$AMP3_LANG" \
  --host \
  --no-https \
  --port "$PORT" \
  --stream "$AMP3_STREAM" \
  --repo "$AMP3_REPO" \
  --origin "$AMP3_ORIGIN"

touch "$INSTALLED_MARKER"
echo "AMP 3 package installation completed."
