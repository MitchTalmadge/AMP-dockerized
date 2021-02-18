# AMP-dockerized
[![Docker Cloud Build Status](https://img.shields.io/docker/cloud/build/mitchtalmadge/amp-dockerized)](https://hub.docker.com/r/mitchtalmadge/amp-dockerized)

This repository bundles [CubeCoders AMP](https://cubecoders.com/AMP) into a Debian-based [Docker image.](https://hub.docker.com/r/mitchtalmadge/amp-dockerized)
(`mitchtalmadge/amp-dockerized:latest`) so that you can set up game servers with ease!

In a nutshell, AMP (Application Management Panel) allows you to manage one or more game servers from a web UI. You need a [CubeCoders AMP Licence](https://cubecoders.com/AMP#buyAMP) to use this image.

Updates to AMP are automatically bundled into new Docker images. We check for updates hourly.

*Please note:* This is a community-made unofficial image, and is not endorsed by CubeCoders.

# Getting Help

**Please DO NOT bug CubeCoders for support without first asking here; they do not support nor endorse this image and will tell you that you are on your own.**

If you need help with AMP when using this image, please [create an issue](https://github.com/MitchTalmadge/AMP-dockerized/issues/new) and we will figure it out! 

## Unraid
If you are using Unraid, please check out [this support topic](https://forums.unraid.net/topic/98290-support-amp-application-management-panel-corneliousjd-repo/) made by one of our community members, [@CorneliousJD](https://github.com/CorneliousJD)!

 
# Supported Modules

**Tested and Working:**

- Factorio
- McMyAdmin
- Minecraft Java Edition
- Minecraft Bedrock Edition
- srcds (GMod, TF2, ...)
- StarBound
 
**Untested:**
 
- [Everything Else](https://github.com/CubeCoders/AMP/wiki/Supported-Applications-Compatibility)

If you are able to get an untested module working, please make an issue about it so we can add it to the tested list and create an example `docker-compose.yml` config!

If you are *not* able to get a module working, make an issue and we can work together to figure out a solution!

# Configuration

I recommend using Docker Compose to set up the image. Sample configurations are provided for each 
module in the `example-configs` directory in the [GitHub repo](https://github.com/MitchTalmadge/AMP-dockerized).

## MAC Address (Important! Please read.)
AMP is designed to detect hardware changes and will de-activate all instances when something significant changes. 
This is to stop people from sharing pre-activated instances and bypassing the licencing server. One way of detecting
changes is to look at the MAC address of the host's network card. A change here will de-activate instances.

By default, Docker assigns a new MAC address to a container every time it is restarted. Therefore, unless you want to
painstakingly re-activate all your instances on every server reboot, you need to assign a permanent MAC address.

For most people, this can be accomplished by generating a random MAC address in Docker's acceptable range.
The instructions to do so are as follows:

- Visit this page: https://miniwebtool.com/mac-address-generator/
- Put `02:42:AC` in as the prefix
- Choose the format with colons `:`
- Generate
- Copy the generated MAC and use it when starting the container.
  - For `docker run`, use the following flag: (Substitute your generated MAC)
  
    `--mac-address="02:42:AC:XX:XX:XX"`
  - For Docker Compose, use the following key next to `image`:
  
    `mac_address: 02:42:AC:XX:XX:XX`
    
If you have a unique network situation, a random MAC may not work for you. In that case you will need
to come up with your own solution to prevent address conflicts.

If you need help with any of this, please make an issue.

## Ports

Here's a rough (and potentially incorrect) list of default ports for the various modules. Each module also exposes port 8080 for the Web UI (can be changed with environment variables). If you find an inaccuracy, open an issue!

| Module Name | Default Ports                                                                                                                                                                                  |
|-------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `ADS`       | No additional ports.                                                                                                                                                                           |
| `ARK`       | UDP 27015 & UDP 7777 & UDP 7778 ([Guide](https://ark.gamepedia.com/Dedicated_Server_Setup))                                                                                                    |
| `Arma3`     | UDP 2302 to UDP 2306 ([Guide](https://community.bistudio.com/wiki/Arma_3_Dedicated_Server))                                                                                                    |
| `Factorio`  | UDP 34197 ([Guide](https://wiki.factorio.com/Multiplayer))                                                                                                                                     |
| `FiveM`     | UDP 30120 & TCP 30120 ([Guide](https://docs.fivem.net/docs/server-manual/setting-up-a-server/))                                                                                                 |
| `Generic`   | Completely depends on what you do with it.                                                                                                                                                     |
| `JC2MP`     | UDP 27015 & UDP 7777 & UDP 7778 (Unconfirmed!)                                                                                                                                                 |
| `McMyAdmin` | TCP 25565                                                                                                                                                                                      |
| `Minecraft` | TCP 25565 (Java) or UDP 19132 (Bedrock)                                                                                                                                                        |
| `Rust`      | UDP 28015 ([Guide](https://developer.valvesoftware.com/wiki/Rust_Dedicated_Server))                                                                                                            |
| `SevenDays` | UDP 26900 to UDP 26902 & TCP 26900 ([Guide](https://developer.valvesoftware.com/wiki/7_Days_to_Die_Dedicated_Server))                                                                          |
| `srcds`     | Depends on the game. Usually UDP 27015. ([List of games under srcds](https://github.com/CubeCoders/AMP/wiki/Supported-Applications-Compatibility#applications-running-under-the-srcds-module)) |
| `StarBound` | TCP 21025 ([Guide](https://starbounder.org/Guide:Setting_Up_Multiplayer))                                                                                                                      |

Just a quick note about ports: some games use TCP, some games use UDP. Make sure you are using the right protocol. Don't fall into the trap of accidentally mapping a TCP port for a UDP game -- you won't be able to connect. 

## Environment Variables

### Licence

| Name      | Description                                                                                                          | Default Value                                         |
|-----------|----------------------------------------------------------------------------------------------------------------------|-------------------------------------------------------|
| `LICENCE` | The licence key for CubeCoders AMP. You can retrieve or buy this on [their website.](https://manage.cubecoders.com/) | No Default. AMP will not boot without a real licence. |

**Important Details:**
- _Americans:_ This is spelled licenCe not licenSe. Got me a few times.
- When a McMyAdmin licence is provided, the one and only instance will be a Minecraft instance. This cannot be overridden;
 you must buy a new license to use AMP with other/multiple games.

### Module

| Name     | Description                                                      | Default Value |
|----------|------------------------------------------------------------------|---------------|
| `MODULE` | Which Module to use for the main instance created by this image. | `ADS`         |

To run multiple game servers under this image, use the default value of `ADS` (Application Deployment Service) which allows you to create various modules from the web ui.

To be clear, this Docker image creates ONE instance by default. If you want to create more, use `ADS` as the first
  instance, and create the rest with the web UI. Otherwise, you can pick any other module from the list.

Here are the accepted values for the `MODULE` variable:

| Module Name | Description                                                                                                   |
|-------------|---------------------------------------------------------------------------------------------------------------|
| `ADS`       | Application Deployment Service. Used to manage multiple modules. Need multiple game servers? Pick this.       |
| `ARK`       |                                                                                                               |
| `Arma3`     |                                                                                                               |
| `Factorio`  |                                                                                                               |
| `FiveM`     |                                                                                                               |
| `Generic`   | For advanced users. You can craft your own module for any other game using this. You're on your own here.     |
| `JC2MP`     | Just Cause 2                                                                                                  |
| `McMyAdmin` | If you have a McMyAdmin Licence, this will be picked for you no matter what. It is equivalent to `Minecraft`. |
| `Minecraft` | Includes Java (Spigot, Bukkit, Paper, etc.) and Bedrock servers.                                              |
| `Rust`      |                                                                                                               |
| `SevenDays` | 7-Days To Die                                                                                                 |
| `srcds`     | Source-based games like TF2, GMod, etc. [Full List](https://github.com/CubeCoders/AMP/wiki/Supported-Applications-Compatibility#applications-running-under-the-srcds-module)                                                                    |
| `StarBound` |                                                                                                               |
    
### User/Group

| Name  | Description                                                          | Default Value |
|-------|----------------------------------------------------------------------|---------------|
| `UID` | The ID of the user (on the host) who will own the ampdata volume.    | `1000`        |
| `GID` | The ID of the group for the user above.                              | `1000`        |

When not specified, these both default to ID `1000`; i.e. the first non-system user on the host.

### Timezone
| Name | Description                                                          | Default Value |
|------|----------------------------------------------------------------------|---------------|
| `TZ` | The timezone to use in the container. Pick from the "TZ database name" column on [this page](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones)   | `Etc/UTC`        |

Example: `TZ=America/Denver`

### Web UI

| Name       | Description                                                                                                                                             | Default Value |
|------------|---------------------------------------------------------------------------------------------------------------------------------------------------------|---------------|
| `PORT`     | The port of the Web UI for the main instance. Since you can map this to any port on the host, there's hardly a reason to change it.                     | `8080`        |
| `USERNAME` | The username of the admin user created on first boot.                                                                                                   | `admin`       |
| `PASSWORD` | The password of the admin user. This value is only used when creating the new user. If you use the default value, please change it after first sign-in. | `password`    |

### Nightly Builds
| Name  | Description                                                          | Default Value |
|-------|----------------------------------------------------------------------|---------------|
| `NIGHTLY` | Set to any value to enable nightly builds. All instances will be migrated to nightly builds on next image start. Unset this variable to go back to MainLine builds (stable releases).    | UNSET        |


## Volumes

| Mount Point           | Description                                                                                                                                                                                                        |
|-----------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `/home/amp/.ampdata`  | **Required!** This volume contains everything AMP needs to run. This includes all your instances, all their game files, the web ui sign-in info, etc. Essentially, without creating this volume, AMP will be wiped on every boot.|

## HTTPS / SSL / TLS

Setting up HTTPS is independent of the Docker image. Just follow this [official guide](https://github.com/CubeCoders/AMP/wiki/Setting-up-HTTPS-with-AMP) 
and when it tells you to access `/home/AMP/.ampdata`, access the volume you mapped on the host instead. It has the same contents.
To restart the AMP instances, just restart the Docker container.

Or, just put [CloudFlare](https://www.cloudflare.com/) and its free SSL cert in front of your web UI and save yourself hours of pain.

# Upgrading AMP

To upgrade, all you have to do is pull our latest Docker image! We automatically check for AMP updates every hour. When a new version is released, we build and publish an image both as a standalone tag and on `:latest`. 

# Contributing

I welcome contributors! Just open an issue first, or post in one of the contibution welcome / help wanted issues, so that we can discuss before you start coding. Thank you for helping!!
