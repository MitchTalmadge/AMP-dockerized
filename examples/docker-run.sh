#!/usr/bin/env bash
set -euo pipefail

IMAGE=amp-v3-dockerized:beta
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd -- "$SCRIPT_DIR/.." && pwd)"
DATA_DIR=${AMP3_DATA_DIR:-"$PROJECT_ROOT/ampdata"}

mkdir -p "$DATA_DIR"
docker build --platform linux/amd64 -t "$IMAGE" "$PROJECT_ROOT"

docker run -d \
  --name amp3 \
  --restart unless-stopped \
  --platform linux/amd64 \
  --cgroupns host \
  --tty \
  --stop-signal SIGRTMIN+3 \
  --cap-add SYS_ADMIN \
  --cap-add NET_ADMIN \
  --security-opt apparmor=unconfined \
  --tmpfs /run \
  --tmpfs /run/lock \
  --volume "$DATA_DIR:/opt/cubecoders/amp3/data" \
  --volume /sys/fs/cgroup:/sys/fs/cgroup:rw \
  --publish 8443:8443/tcp \
  --env PORT=8443 \
  --env AMP3_STREAM=preview \
  --env AMP3_LANG=en \
  --env TZ=Etc/UTC \
  --env SYSTEMD_LOG_TARGET=console \
  --env SYSTEMD_LOG_LEVEL=info \
  "$IMAGE"

echo "AMP 3 is starting. Complete the first-run wizard at http://localhost:8443/."
echo "Add -p HOST:CONTAINER/tcp or /udp mappings for each game server port you use."
