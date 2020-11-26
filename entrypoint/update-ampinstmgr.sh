#!/bin/bash -e
set +o xtrace

# Migrate bin dir
AMP_BIN_DIR=/home/amp/.ampdata/.bin/
if [ -d /home/amp/.ampdata/bin ]; then
  mv /home/amp/.ampdata/bin/* /home/amp/.ampdata/.bin/ && \
  rm /home/amp/.ampdata/bin
fi

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
wget -nv -c -P ${AMP_BIN_DIR} http://cubecoders.com/Downloads/ampinstmgr.zip
echo "Download complete. Updating ampinstmgr..."
unzip -o ${AMP_BIN_DIR}ampinstmgr.zip -d ${AMP_BIN_DIR}
rm -rf ${AMP_BIN_DIR}ampinstmgr.zip
echo ${HEAD_VERSION} >${CURRENT_VERSION_FILE}
echo "Update complete."
