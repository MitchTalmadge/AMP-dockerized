# AMP 3 in Docker

An unofficial, community-maintained Docker image for CubeCoders AMP 3. The image runs AMP and its managed game servers together in one container, with systemd managing AMP services.

> **AMP 3 is in beta.** This image currently supports `linux/amd64` only. You need a valid AMP licence.

## What the image does

- Downloads CubeCoders' official AMP 3 installer while building the image.
- Installs AMP 3 packages the first time a container starts.
- Keeps AMP settings and server data in `/opt/cubecoders/amp3/data`.
- Hosts the AMP panel and AMP-managed game servers in the same container.

The first container start can take several minutes while AMP is installed. Restarts of that container do not rerun the installer. Recreating a container runs the installer again and uses the configured `AMP3_STREAM` channel.

## Run with Docker Compose

From the repository root:

```bash
docker compose -f examples/docker-compose.yml up -d --build
```

Follow the first-start installer:

```bash
docker exec -it amp3 journalctl -u amp3-bootstrap.service -f
```

When installation finishes, open `http://<docker-host>:8443/` and complete AMP 3's setup wizard. The setup link is also saved to `ampdata/setup-link.txt`.

Check services and logs with:

```bash
docker exec -it amp3 systemctl status amp3 amp3-bus amp3-sysagent
docker exec -it amp3 journalctl -u amp3 -f
```

## Install on Unraid

Use the Docker image published by this repository. Replace `<namespace>/<image>` with the value configured as `DOCKERHUB_IMAGE` in the repository's GitHub settings.

In Unraid, add a container with these settings:

| Setting | Value |
|---|---|
| Repository | `<namespace>/<image>:latest` (or pin a version tag) |
| Network type | `Bridge` |
| AMP panel port | Host `8443` → container `8443`, TCP |
| AMP data path | Host `/mnt/user/appdata/amp3` → container `/opt/cubecoders/amp3/data`, read/write |
| Cgroup mount | Host `/sys/fs/cgroup` → container `/sys/fs/cgroup`, read/write |
| Extra parameters | `--cap-add=SYS_ADMIN --cap-add=NET_ADMIN --security-opt apparmor=unconfined --tmpfs /run --tmpfs /run/lock` |

Keep the container port at `8443` to match `PORT`. If host port `8443` is already in use, change only the host-side port and open AMP at `http://<unraid-ip>:<host-port>/`.

Add these environment variables:

| Variable | Value |
|---|---|
| `PORT` | `8443` |
| `AMP3_STREAM` | `preview` |
| `AMP3_LANG` | `en` |
| `TZ` | Your time zone, such as `America/Denver` |

In Unraid's Advanced View, add the cgroup mount and extra parameters above. Do not enable privileged mode. The container needs the listed capabilities and writable cgroup access for systemd and the AMP system agent; these settings give it elevated access to the host.

On the first start, open the container's Console and run `journalctl -u amp3-bootstrap.service -f` to follow installation. When it completes, open the panel and finish the setup wizard. The setup link is saved at `/mnt/user/appdata/amp3/setup-link.txt` with the path mapping above.

## Game-server ports

Only the AMP panel port is published by default. Add a Docker port mapping for every TCP or UDP port required by each game you host. For example:

```text
25565/tcp   Minecraft Java
19132/udp   Minecraft Bedrock
```

Add the same mappings in Unraid's container settings or to `examples/docker-compose.yml`. Check the game's AMP template for its required ports. After adding ports to a container, recreate it for Docker to apply the mappings.

## Configuration

| Variable | Default | Purpose |
|---|---|---|
| `PORT` | `8443` | AMP web panel port inside the container. Map this container port in Docker. |
| `AMP3_STREAM` | `preview` | Installer channel: `mainline`, `preview`, or `development`. |
| `AMP3_LANG` | `en` | Installer language: `en`, `de`, `fr`, or `nl`. |
| `AMP3_REPO` | `https://cdn-repo.c7rs.com/amp3` | AMP 3 package repository. |
| `AMP3_ORIGIN` | `https://cdn-downloads.c7rs.com/AMP3` | AMP 3 update origin. |
| `TZ` | `Etc/UTC` | Container time zone, for example `America/Denver`. |

AMP creates and manages its own `amp` account. Create the first AMP user in the setup wizard.

## Data and upgrades

Persist `/opt/cubecoders/amp3/data` on the host. Back it up before replacing the container or changing the AMP stream. Do not remove the host data directory when updating the image.

The installer runs once for each newly created container. Normal restarts reuse the installed packages; recreating the container installs the packages currently available on the selected `AMP3_STREAM`. AMP also has its own application update mechanism.

## Docker image publishing

Production and Staging are the two workflows. Both use the shared composite action in `.github/actions/build-image`; the action has no independent trigger or manual Run button. Production also checks pull requests without publishing.

GitHub Actions builds the image for `linux/amd64`. Pull requests and pushes to `master` build the image without publishing it. Production images publish when a `v*` Git tag is pushed, or when **Deploy Production** is run manually with a tag. Staging branches publish a staging tag.

Configure these repository settings under **Settings → Secrets and variables → Actions**:

| Name | Type | Value |
|---|---|---|
| `DOCKERHUB_IMAGE` | Repository variable | Docker Hub repository, such as `yourname/amp3-dockerized` (no tag) |
| `DOCKERHUB_USERNAME` | Repository secret | Docker Hub username |
| `DOCKERHUB_TOKEN` | Repository secret | Docker Hub access token with permission to push to that repository |

After setting these values, push a version tag to publish it and update `latest`:

```bash
git tag v1.0.0
git push origin v1.0.0
```

The versioned tag is suitable for pinning an Unraid container to a specific release; `latest` follows the most recently published production tag. A release build fails with a configuration error if the Docker Hub repository or credentials are missing.

## Host requirements and security

Run the image on a Linux Docker host with systemd-compatible cgroups. Rootless Docker and Docker Desktop are not supported. The image only builds for `linux/amd64`.

The container requires `SYS_ADMIN` and `NET_ADMIN`, writable access to the host cgroup filesystem, and the security settings shown above. These permissions are broader than a typical web application container. The Compose example does not use `privileged: true`.

## Project and support

This is a community container project and is not endorsed or supported by CubeCoders. For image issues, open an issue in [this repository](https://github.com/Tareku99/AMP-v3-dockerized/issues). For AMP behavior or licensing, use [CubeCoders' official support](https://discourse.cubecoders.com/).
