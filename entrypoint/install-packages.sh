#!/usr/bin/env bash
set -Eeuo pipefail
# Build-time extraction, following the AMP 2 image's packaging model.
# apt verifies the signed index and downloaded package hashes. No AMP maintainer
# script runs here: data initialization is implemented separately in this image.
case "$AMP3_STREAM" in mainline|preview|development) ;; *) exit 1 ;; esac
[[ "$AMP3_REPO" =~ ^https://[A-Za-z0-9./_-]+$ ]] || {
  echo "AMP3_REPO must be an HTTPS package repository URL." >&2; exit 1;
}
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
curl -fsSL --retry 3 "$AMP3_REPO/archive.gpg" -o "$work/archive.gpg"
install -m 0644 "$work/archive.gpg" /usr/share/keyrings/cubecoders-amp3.gpg
printf 'Types: deb\nURIs: %s/deb\nSuites: %s\nComponents: main\nArchitectures: amd64\nSigned-By: /usr/share/keyrings/cubecoders-amp3.gpg\n' \
  "$AMP3_REPO" "$AMP3_STREAM" >/etc/apt/sources.list.d/cubecoders-amp3.sources
apt-get update
cd "$work"
apt-get download amp3 amp3-sysagent
for package in ./*.deb; do
  dpkg-deb --extract "$package" /
done
install -d /usr/local/share/amp3-docker
printf '%s\n' "$AMP3_STREAM" >/usr/local/share/amp3-docker/package-stream
printf '%s\n' "$AMP3_REPO" >/usr/local/share/amp3-docker/package-repo
dpkg-deb --field ./amp3_*.deb Version >/usr/local/share/amp3-docker/package-version
