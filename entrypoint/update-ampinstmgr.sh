#!/bin/bash -e
set +o xtrace

AMP_BIN_DIR=/opt/cubecoders/amp/
CURRENT_VERSION_FILE=/home/amp/.ampdata/ampinstmgr-version.txt
VERSIONS_PATH=/tmp/AMPVersions.json

wget -nv https://cubecoders.com/AMPVersions.json -O ${VERSIONS_PATH}
HEAD_VERSION=$(cat ${VERSIONS_PATH} | jq -r '.InstanceManagerCLI')
rm -irf ${VERSIONS_PATH}
echo "> Latest Version: ${HEAD_VERSION}"

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
DL_PATH=/tmp/ampinstmgr.zip
wget -nv http://cubecoders.com/Downloads/ampinstmgr.zip -O ${DL_PATH}
echo "Download complete. Updating ampinstmgr..."
unzip -o ${DL_PATH} -d ${AMP_BIN_DIR}
echo ${HEAD_VERSION} >${CURRENT_VERSION_FILE}
rm -irf ${DL_PATH}
echo "Update complete."
