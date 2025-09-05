> [!CAUTION]
> **This is a community-made unofficial image, and is NOT endorsed by CubeCoders.**
> **Please DO NOT ask CubeCoders for support. They do not support nor endorse this image and will understandably tell you that you are on your own.**
> 
> This project is community driven by people who have full time responsibilities elsewhere. You should be able to navigate Docker, Linux, bash, etc. and feel comfortable debugging containers on your own if you intend to use this image. I will help if I get time, but I have a full time job and family that I want to hang out with.
>
> That said, if you have time and are able to help, please feel free! I love PRs!

> [!NOTE]  
> A lack of commits & releases does not mean this project is dead. The image is configured by default to auto-update AMP on startup, meaning that new image releases are often not necessary.

# AMP-dockerized
This repository bundles [CubeCoders AMP](https://cubecoders.com/AMP) into a Debian-based [Docker image.](https://hub.docker.com/r/mitchtalmadge/amp-dockerized)
(`mitchtalmadge/amp-dockerized:latest`) so that you can set up game servers with ease! 

In a nutshell, AMP (Application Management Panel) allows you to manage one or more game servers from a web UI. You need a [CubeCoders AMP Licence](https://cubecoders.com/AMP#buyAMP) to use this image.

> [!WARNING]
> **This is a community-made unofficial image, and is not endorsed by CubeCoders.**

# Getting Help

You can make an issue if you need help, but I am not always available for quick assistance. Using AMP in this unofficial docker container is an advanced endeavour and you may need to do a little self-debugging and experimentation. Please remember to make backups of important data.

If you need help with AMP when using this image, please [create an issue](https://github.com/MitchTalmadge/AMP-dockerized/issues/new) in this repository.

If you have coding skills and find this repository useful, please consider helping out by answering questions in the issues or making pull requests to fix bugs. I really can't do this alone.

> [!WARNING]
> **Please DO NOT ask CubeCoders for support. They do not support nor endorse this image and will tell you that you are on your own.**

## Unraid
If you are using Unraid, there is a [support topic](https://forums.unraid.net/topic/98290-support-amp-application-management-panel-corneliousjd-repo/) on their forums. I do not officially support Unraid but I'll try to help if I have time.
 
# Supported Modules

**Tested and Working:**

- Factorio
- McMyAdmin
- Minecraft Java Edition
- Minecraft Bedrock Edition
- srcds (GMod, TF2, ...)
- StarBound
- Valheim
 
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
  - For Docker Compose, you need to add a `networks` section like so:
  
    ```yaml
    # Your config may look a little different -- focus on the networks section
    services:
      amp:
        image: mitchtalmadge/amp-dockerized
        networks:
          default:
            mac_address: 02:42:AC:XX:XX:XX
        ...
    ```
    
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
| `FiveM`     | UDP 30120 & TCP 30120 ([Guide](https://docs.fivem.net/docs/server-manual/setting-up-a-server/))                                                                                                |
| `Generic`   | Completely depends on what you do with it.                                                                                                                                                     |
| `JC2MP`     | UDP 27015 & UDP 7777 & UDP 7778 (Unconfirmed!)                                                                                                                                                 |
| `McMyAdmin` | TCP 25565                                                                                                                                                                                      |
| `Minecraft` | TCP 25565 (Java) or UDP 19132 (Bedrock)                                                                                                                                                        |
| `Rust`      | UDP 28015 ([Guide](https://developer.valvesoftware.com/wiki/Rust_Dedicated_Server))                                                                                                            |
| `SevenDays` | UDP 26900 to UDP 26902 & TCP 26900 ([Guide](https://developer.valvesoftware.com/wiki/7_Days_to_Die_Dedicated_Server))                                                                          |
| `srcds`     | Depends on the game. Usually UDP 27015. ([List of games under srcds](https://github.com/CubeCoders/AMP/wiki/Supported-Applications-Compatibility#applications-running-under-the-srcds-module)) |
| `StarBound` | TCP 21025 ([Guide](https://starbounder.org/Guide:Setting_Up_Multiplayer))                                                                                                                      |
| `Valheim`   | UDP 5678 → 5680                                                                                                                                                                                |

Just a quick note about ports: some games use TCP, some games use UDP. Make sure you are using the right protocol. Don't fall into the trap of accidentally mapping a TCP port for a UDP game -- you won't be able to connect. 

## Environment Variables

### Licence

| Name          | Description                                                                                                              | Default Value                                         |
|---------------|--------------------------------------------------------------------------------------------------------------------------|-------------------------------------------------------|
| `AMP_LICENCE` | The licence key for CubeCoders AMP. You can retrieve or buy this on [their website.](https://manage.cubecoders.com/)     | No Default. AMP will not boot without a real licence. |

**Important Details:**
- 🇺🇸Americans🇺🇸: This is spelled licen**C**e not licen**S**e. Got me a few times 😂
- When a McMyAdmin licence is provided, the one and only instance will be a Minecraft instance. This cannot be overridden;
 you must buy a new licence to use AMP with other/multiple games.

### Auto-Update
| Name              | Description                                                                                     | Default Value |
|-------------------|-------------------------------------------------------------------------------------------------|---------------|
| `AMP_AUTO_UPDATE` | Set to `false` if you would not like AMP to automatically update when you reboot the container. | `true`        |

By default, AMP will automatically update itself to the latest version when the container is started or restarted. 
If you prefer to manage updates manually, set this variable to `false` and you can still update AMP from the web UI.

### Module

| Name         | Description                                                                                                                                         | Default Value |
|--------------|-----------------------------------------------------------------------------------------------------------------------------------------------------|---------------|
| `AMP_MODULE` | Which Module to use for the Main instance created by this image (note: changing this value will have no effect after the Main instance is created). | `ADS`         |

To run multiple game servers under this image, use the default value of `ADS` (Application Deployment Service) which allows you to create various modules from the web UI.

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
| `Valheim`   |                                                                                                               |
    
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
| `IPBINDING`| Which IP address the main instance will bind to. In almost all cases you should leave this as the default, unless you are doing something advanced.     | `0.0.0.0`     |
| `USERNAME` | The username of the admin user created on first boot.                                                                                                   | `admin`       |
| `PASSWORD` | The password of the admin user. This value is only used when creating the new user. If you use the default value, please change it after first sign-in. | `password`    |

### Release Stream
| Name                 | Description                                                                                        | Default Value |
|----------------------|----------------------------------------------------------------------------------------------------|---------------|
| `AMP_RELEASE_STREAM` | Valid values are `Mainline` or `Development`. Don't change this unless you know what you're doing. | `Mainline`    |

## Volumes

| Mount Point          | Description                                                                                                                                                                                                                       |
|----------------------|-----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `/home/amp/.ampdata` | **Required!** This volume contains everything AMP needs to run. This includes all your instances, all their game files, the web ui sign-in info, etc. Essentially, without creating this volume, AMP will be wiped on every boot. |
| `/home/amp/scripts`  | This volume allows you to provide custom scripts that will run at certain points during this container's lifecycle. See the section below about custom scripts.                                                                   |

### Custom Scripts

If you would like to run your own shell scripts in this container, which can be useful to e.g. install extra dependencies for a game's plugin, you can use the `/home/amp/scripts` volume.

Currently, only one script is supported: `startup.sh`. Place a file named `startup.sh` into the volume, and it will be run on container startup.

**Example: Installing extra packages**
```sh
echo "Downloading dependencies for Valheim Plus Mod..."
apt-get update && \
apt-get install -y \
        libc6 \
        libc6-dev
```

## HTTPS / SSL / TLS

Setting up HTTPS is independent of the Docker image. Just follow this [official guide](https://github.com/CubeCoders/AMP/wiki/Setting-up-HTTPS-with-AMP) 
and when it tells you to access `/home/AMP/.ampdata`, access the volume you mapped on the host instead. It has the same contents.
To restart the AMP instances, just restart the Docker container.

Or, just put [CloudFlare](https://www.cloudflare.com/) and its free SSL cert in front of your web UI and save yourself hours of pain.

# Contributing

I welcome contributors! Just open an issue first, or post in one of the contibution welcome / help wanted issues, so that we can discuss before you start coding. Thank you for helping!! 
