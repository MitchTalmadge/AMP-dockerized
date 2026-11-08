# Project instructions

This repository builds a community-maintained, all-in-one Docker image for AMP 3. CubeCoders owns AMP 3 and its installer; this repository provides the container packaging.

## Runtime model

- Target platform: Linux/amd64.
- systemd runs as PID 1 in the container.
- On first container start, `amp3-bootstrap.service` runs CubeCoders' official installer with `--host`, so AMP-managed game servers run in this container.
- Persistent AMP data is stored at `/opt/cubecoders/amp3/data`.
- The Docker build downloads the installer; package installation happens at first container start.
- systemd and the AMP system agent need cgroup access and the `SYS_ADMIN` and `NET_ADMIN` capabilities. Keep these requirements documented. Avoid `privileged: true` unless a host-specific issue justifies it.

## Key files

- `Dockerfile`: Debian base image, game-server dependencies, systemd, and installer download.
- `entrypoint/main.sh`: validates environment, persists the machine ID, and starts systemd.
- `entrypoint/amp3-bootstrap.service`: first-start installer service.
- `entrypoint/amp3-bootstrap.sh`: invokes the official AMP 3 installer.
- `examples/docker-compose.yml`: local Linux Compose setup and sample port mappings.
- `.github/workflows/build.yml`: shared amd64 build and optional Docker Hub publishing.
- `.github/workflows/deploy-prod.yml`: production version tags and `latest`.
- `.github/workflows/deploy-staging.yml`: staging image tags.

## AMP 3 settings

- `PORT=8443`
- `AMP3_STREAM=preview` (`mainline`, `preview`, or `development`)
- `AMP3_LANG=en` (`en`, `de`, `fr`, or `nl`)
- `AMP3_REPO=https://cdn-repo.c7rs.com/amp3`
- `AMP3_ORIGIN=https://cdn-downloads.c7rs.com/AMP3`
- `TZ=Etc/UTC`

Create the first AMP account in the web setup wizard.

## Publishing

The publishing workflows target Docker Hub. A repository variable named `DOCKERHUB_IMAGE` and secrets named `DOCKERHUB_USERNAME` and `DOCKERHUB_TOKEN` are required for publishing. Never set a default publishing target that could push a fork's image to another project. Pull requests and `master` builds must not publish.

Do not run image builds or tests unless the current task asks for testing. Docker builds download dependencies and the official AMP 3 installer from the network.
