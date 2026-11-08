# AMP 3 in Docker

<img src="assets/amp3-icon.png" width="128" alt="AMP emblem with an AMP 3 version badge">

Community-maintained container packaging for [CubeCoders AMP 3](https://cubecoders.com/AMP3), combining the control panel and its managed game servers in one Docker container.

**Status:** AMP 3 beta · **Platform:** Linux / amd64 · **Publishing target:** `tareku99/amp-v3-dockerized`

This project provides the Docker environment and startup integration. AMP itself is CubeCoders software and requires an appropriate licence. The project is not affiliated with or endorsed by CubeCoders.

> **Experimental staging redesign:** The extracted-package installation described below is pending Unraid validation. The production `latest` image still uses the earlier installer path.

## Overview

The image is based on Debian 13 and includes systemd, common game-server dependencies, multiple Java runtimes, Mono, and Wine. AMP-managed game-server processes run inside the same container as the panel.

| Component | Behavior |
|---|---|
| Control panel | HTTP on container port `8443` by default |
| Service management | systemd runs as PID 1 |
| AMP installation | Official signed repository packages, extracted during the image build |
| Persistent state | `/opt/cubecoders/amp3/data` |
| Game networking | Explicit TCP and UDP port mappings for each hosted game |
| Architecture | `linux/amd64` |

## Container lifecycle

The image build downloads `amp3` and `amp3-sysagent` through APT using CubeCoders' signed repository metadata, then extracts their payloads without executing AMP package maintainer scripts. This follows the extraction approach used by the AMP 2 image.

At startup, a small root helper prepares directory ownership using open directory descriptors. A separate service runs as `amp` to copy the packaged seed and write initial settings. It does not recursively hand regular data files from root to `amp`, modify host sysctls, or install AMP packages at first boot. Existing usable versions are retained; incomplete or blacklisted seed versions stop initialization for manual review.

The installation redesign is experimental. Avoid testing against the only copy of an existing AMP data directory.

AMP account creation takes place in the web setup wizard. The first-run setup link is recorded in `setup-link.txt` inside the persistent data directory.

## Configuration reference

| Environment variable | Default | Description |
|---|---|---|
| `PORT` | `8443` | Internal HTTP port for the AMP panel |
| `AMP3_ORIGIN` | `https://cdn-downloads.c7rs.com/AMP3` | AMP 3 update origin |
| `TZ` | `Etc/UTC` | Container time zone |

The image creates the `amp` service account. Panel users are managed by AMP.

`AMP3_STREAM` (default `preview`) and `AMP3_REPO` (default `https://cdn-repo.c7rs.com/amp3`) are build arguments. Changing them requires rebuilding the image; incompatible runtime overrides are rejected. `AMP3_LANG` is no longer used because the interactive installer is not invoked.

## Storage and networking

The persistent mount at `/opt/cubecoders/amp3/data` retains AMP state and server data independently of the container. The container's machine identity is also retained there. Container replacement and image updates depend on continued access to this directory; deleting it removes the persistent state.

Only the panel port is mapped in the default Compose example. Game-server ports depend on the application and its AMP template. Typical examples include `25565/tcp` for Minecraft Java and `19132/udp` for Minecraft Bedrock.

Host ports can differ from container ports. Docker applies changes to published port mappings when the container is recreated.

## Unraid setup

> **Compatibility status:** The earlier installer path failed on Unraid with `fs.protected_hardlinks=0`. The staging redesign replaces the root ownership handover that triggers this installer requirement with unprivileged seed creation. It leaves the host setting unchanged. This is a proposed compatibility fix, pending an image build and Unraid validation.

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
| Cgroup namespace | Host (`--cgroupns=host`) |
| Console | Pseudo-TTY (`--tty`) with systemd logging to `console` at `info` level |
| Capabilities | `SYS_ADMIN`, `NET_ADMIN` |
| Temporary filesystems | `/run`, `/run/lock` |
| Security option | `apparmor=unconfined` |

With the example data mapping, the first-run setup link resides at `/mnt/user/appdata/amp3/setup-link.txt`. The panel address uses the Unraid host's IP address and the mapped host port.

### Persistent MAC address

A unique, fixed MAC address is recommended before AMP licence activation so the container's network identity remains stable when it is recreated. Earlier AMP container deployments required this to avoid licence resets; an equivalent requirement has not been confirmed for AMP 3.

Generate an address once using the same website referenced by the original AMP Docker image:

1. Open [MiniWebtool's MAC Address Generator](https://miniwebtool.com/mac-address-generator/).
2. Enter `02:42:AC` in **MAC Address Prefix**.
3. Choose the colon-separated format (`:`).
4. Select **Unicast** and **Locally administered** if address-type options are shown.
5. Generate one address and copy the full result.

The `02` prefix identifies a locally administered, unicast address. The remaining bytes include a randomly generated suffix.

In the container editor, enable **Advanced View** and append the following to **Extra Parameters**, replacing `YOUR_GENERATED_MAC` with the generated address:

```text
--mac-address=YOUR_GENERATED_MAC
```

Keep the existing extra parameters. Each container needs its own address, distinct from other devices on the same network. Reuse the chosen address for subsequent updates and container replacements; do not generate a new one at each startup or copy the host's physical MAC address.

## Runtime requirements

The runtime targets Linux Docker hosts with systemd-compatible cgroups. Rootless Docker and Docker Desktop are outside the supported target environment.

The container shares the host cgroup namespace so its cgroup paths match the bind-mounted hierarchy. A pseudo-TTY provides the console required for visible systemd startup logs. AMP bootstrap and service logs remain available through `journalctl` inside the container.

AMP 3 native game servers launch through `systemd-run` as transient services. The vendor documentation describes a `native.noSystemd` refusal when that facility is absent. Cgroups provide process tracking, limits, and shutdown for those services; they are required for this native, same-container runtime. The host namespace option is retained because it resolved the observed Unraid cgroup-path mismatch. See [packaging notes](docs/container-packaging.md) for the design and validation limits.

systemd and the AMP system agent use elevated capabilities and writable cgroup access. The example configuration also disables AppArmor confinement for the container. It does not use privileged mode.

## Images and updates

Production publishing targets `tareku99/amp-v3-dockerized`. Production releases receive a version tag, an `-amd64` alias, and the moving `latest` tag. Staging builds use separate branch-derived tags and do not update `latest`.

Container release tags identify the packaging release. The bundled AMP package version is resolved during the image build from its selected stream and recorded inside the image at `/usr/local/share/amp3-docker/package-version`. An unchanged image retains the same bundled seed when recreated. AMP also provides its own application update mechanism.

## Repository structure

| Path | Purpose |
|---|---|
| [Dockerfile](Dockerfile) | Base image, runtime dependencies, and package extraction |
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
