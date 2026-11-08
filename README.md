# AMP 3 in Docker

<img src="assets/amp3-icon.png" width="128" alt="AMP emblem with an AMP 3 version badge">

Community-maintained container packaging for [CubeCoders AMP 3](https://cubecoders.com/AMP3), combining the control panel and its managed game servers in one Docker container.

**Status:** AMP 3 beta · **Platform:** Linux / amd64 · **Publishing target:** `tareku99/amp-v3-dockerized`

This project provides the Docker environment and startup integration. AMP itself is CubeCoders software and requires an appropriate licence. The project is not affiliated with or endorsed by CubeCoders.

## Overview

The image is based on Debian 13 and includes systemd, common game-server dependencies, multiple Java runtimes, Mono, and Wine. AMP-managed game-server processes run inside the same container as the panel.

| Component | Behavior |
|---|---|
| Control panel | HTTP on container port `8443` by default |
| Service management | systemd runs as PID 1 |
| AMP installation | Official CubeCoders installer, executed on first container start |
| Persistent state | `/opt/cubecoders/amp3/data` |
| Game networking | Explicit TCP and UDP port mappings for each hosted game |
| Architecture | `linux/amd64` |

## Container lifecycle

The official AMP 3 installer is downloaded during the Docker image build. AMP packages are installed when a newly created container first starts, using the configured release stream.

An ordinary restart reuses that container's installed packages. A replacement container runs installation again against the persistent data directory. Startup can take several minutes while packages are downloaded and installed.

AMP account creation takes place in the web setup wizard. The first-run setup link is recorded in `setup-link.txt` inside the persistent data directory.

## Configuration reference

| Environment variable | Default | Description |
|---|---|---|
| `PORT` | `8443` | Internal HTTP port for the AMP panel |
| `AMP3_STREAM` | `preview` | Installation stream: `mainline`, `preview`, or `development` |
| `AMP3_LANG` | `en` | Installer language: `en`, `de`, `fr`, or `nl` |
| `AMP3_REPO` | `https://cdn-repo.c7rs.com/amp3` | AMP 3 package repository |
| `AMP3_ORIGIN` | `https://cdn-downloads.c7rs.com/AMP3` | AMP 3 update origin |
| `TZ` | `Etc/UTC` | Container time zone |

AMP manages its own `amp` system account. Panel users are managed by AMP.

## Storage and networking

The persistent mount at `/opt/cubecoders/amp3/data` retains AMP state and server data independently of the container. The container's machine identity is also retained there. Container replacement and image updates depend on continued access to this directory; deleting it removes the persistent state.

Only the panel port is mapped in the default Compose example. Game-server ports depend on the application and its AMP template. Typical examples include `25565/tcp` for Minecraft Java and `19132/udp` for Minecraft Bedrock.

Host ports can differ from container ports. Docker applies changes to published port mappings when the container is recreated.

## Unraid setup

The template is named **AMP-v3** and is available as [unraid/amp3.xml](unraid/amp3.xml). It defines the published image, panel port, persistent data path, and required runtime permissions, targeting `tareku99/amp-v3-dockerized:latest`.

For manual installation, the template file belongs at `/boot/config/plugins/dockerMan/templates-user/my-amp3.xml` on the Unraid boot device. Saved templates are available from **Docker > Add Container > Template**, where the entry is named **AMP-v3**. Community Applications availability depends on submission review and catalog publication.

The following values describe the intended configuration for an amd64 Unraid host. Unraid compatibility testing is pending.

| Setting | Value |
|---|---|
| Image publishing target | `tareku99/amp-v3-dockerized` |
| Production tag | `latest`, or a versioned release tag |
| Network | Bridge |
| Panel mapping | Host `8443` to container `8443/tcp` |
| Example data mapping | `/mnt/user/appdata/amp3` to `/opt/cubecoders/amp3/data`, read/write |
| Cgroup mapping | `/sys/fs/cgroup` to `/sys/fs/cgroup`, read/write |
| Capabilities | `SYS_ADMIN`, `NET_ADMIN` |
| Temporary filesystems | `/run`, `/run/lock` |
| Security option | `apparmor=unconfined` |

With the example data mapping, the first-run setup link resides at `/mnt/user/appdata/amp3/setup-link.txt`. The panel address uses the Unraid host's IP address and the mapped host port.

### Persistent MAC address

A unique, fixed MAC address is recommended before AMP licence activation so the container's network identity remains stable when it is recreated. Earlier AMP container deployments required this to avoid licence resets; an equivalent requirement has not been confirmed for AMP 3.

Generate an address once in the **Unraid terminal**:

```bash
printf '02:42:AC:%s\n' "$(od -An -N3 -tx1 /dev/urandom | xargs | tr ' ' ':')"
```

The `02` prefix identifies a locally administered, unicast address. The remaining bytes include a randomly generated suffix.

In the container editor, enable **Advanced View** and append the following to **Extra Parameters**, replacing `YOUR_GENERATED_MAC` with the command's output:

```text
--mac-address=YOUR_GENERATED_MAC
```

Keep the existing extra parameters. Each container needs its own address, distinct from other devices on the same network. Reuse the chosen address for subsequent updates and container replacements; do not generate a new one at each startup or copy the host's physical MAC address.

## Runtime requirements

The runtime targets Linux Docker hosts with systemd-compatible cgroups. Rootless Docker and Docker Desktop are outside the supported target environment.

systemd and the AMP system agent use elevated capabilities and writable cgroup access. The example configuration also disables AppArmor confinement for the container. It does not use privileged mode.

## Images and updates

Production publishing targets `tareku99/amp-v3-dockerized`. Production releases receive a version tag, an `-amd64` alias, and the moving `latest` tag. Staging builds use separate branch-derived tags and do not update `latest`.

Container release tags identify the packaging release. They do not pin the AMP package version: installation resolves packages from `AMP3_STREAM` when a replacement container first starts. AMP also provides its own application update mechanism.

## Repository structure

| Path | Purpose |
|---|---|
| [Dockerfile](Dockerfile) | Base image, runtime dependencies, and installer download |
| [entrypoint/](entrypoint/) | Startup validation, machine identity, and AMP bootstrap service |
| [examples/docker-compose.yml](examples/docker-compose.yml) | Compose configuration with persistent storage and sample game ports |
| [examples/docker-run.sh](examples/docker-run.sh) | Equivalent Docker CLI example |
| [unraid/amp3.xml](unraid/amp3.xml) | AMP 3 container template for Unraid Docker Manager |
| [.github/actions/build-image/](.github/actions/build-image/) | Shared build and publishing action |
| [.github/workflows/](.github/workflows/) | Production and Staging workflows |

Pull requests and pushes to `master` build without publishing. Production publishing is triggered by `v*` tags or a manual production release. Staging branch builds publish staging tags.

## Project scope and support

Repository code, templates, metadata, and documentation are covered by the [MIT license](LICENSE), with upstream attribution preserved. AMP software and branding have [separate licensing and attribution](LICENSE.md).

This repository covers container packaging and startup integration. AMP features, beta availability, licensing, and application behavior are maintained by CubeCoders.

[Source repository](https://github.com/Tareku99/AMP-v3-dockerized) · [CubeCoders support](https://discourse.cubecoders.com/)
