#!/bin/bash -e
set -o xtrace

# Create User
groupadd \
  --gid "${GID}" \
  -r \
  amp
useradd \
  --uid "${UID}" \
  --gid "${GID}" \
  --no-log-init \
  --shell /bin/bash \
  -r \
  -m \
  amp

# Set up environment
cd /home/amp

# Create ADS
sudo -u amp ampinstmgr CreateInstance ADS ADSMain 0.0.0.0 ${PORT} "${LICENCE}" "${USERNAME}" "${PASSWORD}"

# Launch ADS
(cd .ampdata/instances/ADSMain && exec sudo -u amp ./AMP_Linux_x86_64)
