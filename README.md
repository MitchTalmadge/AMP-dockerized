> [!CAUTION]
> **This is a community-made unofficial image, and is NOT endorsed by CubeCoders.**
> **Please DO NOT ask CubeCoders for support if you use this image. They do not support nor endorse this image and will understandably tell you that you are on your own.**
> 
> This project is community driven by people who have full time responsibilities elsewhere. You should be able to navigate Docker, Linux, bash, etc. and feel comfortable debugging containers on your own if you intend to use this image. I will help if I get time, but I have a full time job and some family and kitty cats that I want to hang out with! 😸
>
> That said, if you have time and are able to help, please feel free! I love PRs!

> [!NOTE]  
> A lack of commits & releases does not mean this project is dead. This image is effectively an "operating system" for AMP to run on. AMP itself can be updated through its web UI at any time. Infrequently, we may need to push a new image update to support a new version of AMP.

# AMP-dockerized
This repository bundles [CubeCoders AMP](https://cubecoders.com/AMP) into a Debian-based [Docker image.](https://hub.docker.com/r/mitchtalmadge/amp-dockerized)
(`mitchtalmadge/amp-dockerized:latest`) so that you can set up game servers with ease! 

In a nutshell, AMP (Application Management Panel) allows you to manage one or more game servers from a web UI. You need a [CubeCoders AMP Licence](https://cubecoders.com/AMP) to use AMP; this image does not bypass that requirement.

> [!WARNING]
> **This is a community-made unofficial image, and is not endorsed by CubeCoders.**

# Getting Help

You can make an issue if you need help, but I am not always available for quick assistance. Using AMP in this unofficial docker container is an advanced endeavour and you may need to do a little self-debugging and experimentation. Please remember to make backups of important data.

If you need help with AMP when using this image, please [create an issue](https://github.com/MitchTalmadge/AMP-dockerized/issues/new) in this repository.

If you have coding skills and find this repository useful, please consider helping out by answering questions in the issues or making pull requests to fix bugs. I really can't do this alone.

> [!WARNING]
> **Please DO NOT ask CubeCoders for support. They do not support nor endorse this image and will tell you that you are on your own.**

## Unraid Support
If you are using Unraid, you may want to check out the [support topic](https://forums.unraid.net/topic/98290-support-amp-application-management-panel-corneliousjd-repo/) on their forums.

This image works great on Unraid and I even bought the software just to make sure it worked (and now I use Unraid for all sorts of things!)

I will try to help out where I am able.
 
# Supported Game Servers

**Tested and Working:**

- Factorio
- Garry's Mod (GMod)
- McMyAdmin 
- Minecraft Java Edition
- Minecraft Bedrock Edition
- Satisfactory
- StarBound
- Team Fortress 2
- Valheim
 
**Untested:**
 
- Basically everything else. Please see [CubeCoders' own compatibility list](https://discourse.cubecoders.com/t/supported-applications-compatibility/1828). If it runs on Linux according to this table, it _should_ work on this image. Probably.

If you are able to get an untested game working, let me know so I can help make an example for everyone else!

If you are *not* able to get a game working, make an issue and we can work together to figure out a solution!

# Configuration

I recommend using Unraid or Docker Compose to set up the image. You could also just use `docker run`. [Example scripts and configurations can be found here.](./examples).

## MAC Address (Required! Please read!)
> [!CAUTION]
> You must follow these instructions or AMP will be de-activated every time it boots!

AMP is designed to detect hardware changes and will de-activate all instances when something significant changes. By default, Docker assigns a new MAC address to a container every time it is restarted, which is detected as a significant change, and triggers a licence key reset. Therefore, unless you want to painstakingly re-activate all your instances on every server reboot, you need to assign a permanent MAC address.

For most people, this can be accomplished by generating a random MAC address in Docker's acceptable range.
The instructions to do so are as follows:

1. Visit this page: https://miniwebtool.com/mac-address-generator/
2. Put `02:42:AC` in as the prefix
3. Choose the format with colons `:`
4. Generate
5. Copy the generated MAC and use it when starting the container.
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
    
If you have a unique network situation, a random MAC may not work for you. In that case you will need to come up with your own solution to prevent address conflicts.

Please refer to the [example configurations](./examples) if needed.

For additional help with any of this, please make an issue.

## Ports

Here's a rough list of default ports for the various game servers. AMP also exposes port 8080 for the Web UI (can be changed with environment variables). If you find an inaccuracy, open an issue!

| Module Name | Default Ports                                                                                                                                                                                  |
|-------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `ARK`       | UDP 27015 & UDP 7777 & UDP 7778 ([Guide](https://ark.gamepedia.com/Dedicated_Server_Setup))                                                                                                    |
| `Arma3`     | UDP 2302 to UDP 2306 ([Guide](https://community.bistudio.com/wiki/Arma_3_Dedicated_Server))                                                                                                    |
| `Factorio`  | UDP 34197 ([Guide](https://wiki.factorio.com/Multiplayer))                                                                                                                                     |
| `FiveM`     | UDP 30120 & TCP 30120 ([Guide](https://docs.fivem.net/docs/server-manual/setting-up-a-server/))                                                                                                |
| `JC2MP`     | UDP 27015 & UDP 7777 & UDP 7778 (Unconfirmed!)                                                                                                                                                 |
| `McMyAdmin` | TCP 25565                                                                                                                                                                                      |
| `Minecraft` | TCP 25565 (Java) or UDP 19132 (Bedrock)                                                                                                                                                        |
| `Rust`      | UDP 28015 ([Guide](https://developer.valvesoftware.com/wiki/Rust_Dedicated_Server))                                                                                                            |
| `SevenDays` | UDP 26900 to UDP 26902 & TCP 26900 ([Guide](https://developer.valvesoftware.com/wiki/7_Days_to_Die_Dedicated_Server))                                                                          |
| `StarBound` | TCP 21025 ([Guide](https://starbounder.org/Guide:Setting_Up_Multiplayer))                                                                                                                      |
| `Valheim`   | UDP 5678 → 5680                                                                                                                                                                                |

> [!IMPORTANT]
> Make sure you are using the right protocol. If you accidentally map a TCP port for a UDP game, you won't be able to connect! 

## Environment Variables

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

### Auto-Update
| Name              | Description                                                                                     | Default Value |
|-------------------|-------------------------------------------------------------------------------------------------|---------------|
| `AMP_AUTO_UPDATE` | Set to `true` if you would like AMP to automatically update when you reboot the container. | `true`        |

By default, AMP will automatically update when this container reboots. You can update AMP using the web UI as well - AMP will alert you when an update is available through its UI. The updates to this container image are not directly tied to AMP updates. Think of this container more like an all-in-one "operating system" for AMP. New versions of this container are only necessary when AMP is not working correctly. If you would like to disable automatic updates on container reboot, you can set `AMP_AUTO_UPDATE` to `false`.

## Volumes

> [!CAUTION]
> If you do not set up a volume as described, your game data will be wiped every time the container updates.

| Mount Point  | Description                                                                                                                                                                                                                  |
|--------------|------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `/home/amp/` | **Required!** This volume contains everything AMP needs to run. This includes all your instances, all their game & save files, the web UI sign-in info, etc. Without creating this volume, AMP would be wiped on every boot. |

# Advanced Configuration
Please see the [advanced configuration wiki page](https://github.com/MitchTalmadge/AMP-dockerized/wiki/Advanced-Configuration) for more that you can do with this container.

# Contributing

I welcome contributors! Just open an issue first, or post in one of the contibution welcome / help wanted issues, so that we can discuss before you start coding. Thank you for helping!! 

