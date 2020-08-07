#!/bin/bash -e
set +o xtrace
echo "Checking for ampinstmgr updates..."

wget -nv https://cubecoders.com/AMPVersions.json -O /tmp/AMPVersions.json
HEAD_VERSION=$(cat /tmp/AMPVersions.json | jq -r '.InstanceManagerCLI')
rm -irf /tmp/AMPVersions.json
echo "> Latest Version: ${HEAD_VERSION}"

CURRENT_VERSION_FILE=/home/amp/.ampdata/ampinstmgr-version.txt
if [ -f ${CURRENT_VERSION_FILE} ]; then
  CURRENT_VERSION=$(cat ${CURRENT_VERSION_FILE})
  echo "> Current Version: ${CURRENT_VERSION}"
  if [ "${HEAD_VERSION}" = "${CURRENT_VERSION}" ]; then
    echo "No updates needed."
    exit
  fi
else
  echo "> Current Version: Unknown"
fi

echo "Downloading latest ampinstmgr... (This can take ~5 minutes; CubeCoders limits their download speeds to a crawl.)"
wget -nv http://cubecoders.com/Downloads/ampinstmgr.zip -O /tmp/ampinstmgr.zip
echo "Download complete. Updating ampinstmgr..."
unzip -o /tmp/ampinstmgr.zip -d /opt/cubecoders/amp/
echo ${HEAD_VERSION} >${CURRENT_VERSION_FILE}
rm -irf /tmp/ampinstmgr.zip
echo "Update complete."
