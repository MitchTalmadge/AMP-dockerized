# AMP-dockerized
[![Docker Cloud Build Status](https://img.shields.io/docker/cloud/build/mitchtalmadge/amp-dockerized)](https://hub.docker.com/r/mitchtalmadge/amp-dockerized)

This repository bundles [CubeCoders AMP](https://cubecoders.com/AMP) into a Debian-based [Docker image.](https://hub.docker.com/r/mitchtalmadge/amp-dockerized) 
(`mitchtalmadge/amp-dockerized:latest`)

In a nutshell, AMP (Application Management Panel) allows you to manage one or more game servers from a web UI.

*Disclaimer:* I (Mitch Talmadge) did not create AMP and am not associated with CubeCoders. I simply made it work with Docker because
 I hate installing things.
 
# Supported Modules

**Tested and Working:**

- Minecraft
- McMyAdmin
 
**Untested:**
 
- [Everything Else](https://github.com/CubeCoders/AMP/wiki/Supported-Applications-Compatibility)

If you are able to get an untested module working, please add it to the tested list, create an example `docker-compose.yml` config, and add any further instructions to our Wiki.

If you are *not* able to get a module working, make an issue and we can work together to figure out a solution.

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

If you want to run multiple game servers, 
  you can use the default value of `ADS` (Application Deployment Service) which allows you to create various modules
  from the web ui.

To be clear, this Docker image creates ONE instance by default. If you want to create more, use `ADS` as the first
  instance and create the rest with the web ui.

If you only want one game instance, you can select from the list of modules below:

| Module Name | Description                                                                                                   |
|-------------|---------------------------------------------------------------------------------------------------------------|
| `ADS`       | Application Deployment Service. Used to manage multiple modules.                                              |
| `ARK`       |                                                                                                               |
| `Arma3`     |                                                                                                               |
| `Factorio`  |                                                                                                               |
| `FiveM`     |                                                                                                               |
| `Generic`   | Only for advanced users.                                                                                      |
| `JC2MP`     |                                                                                                               |
| `McMyAdmin` | If you have a McMyAdmin Licence, this will be picked for you no matter what. It is equivalent to `Minecraft`. |
| `Minecraft` |                                                                                                               |
| `Rust`      |                                                                                                               |
| `SevenDays` |                                                                                                               |
| `srcds`     | Source-based games like TF2, GMod, etc.                                                                       |
| `StarBound` |                                                                                                               |
    
### User/Group

| Name  | Description                                                          | Default Value |
|-------|----------------------------------------------------------------------|---------------|
| `UID` | The ID of the user (on the host) who will own the  /ampdata  volume. | `1000`        |
| `GID` | The ID of the group for the user above.                              | `1000`        |

When not specified, these both default to ID `1000`; i.e. the first non-system user on the host.

### Web UI

| Name       | Description                                                                                                                                             | Default Value |
|------------|---------------------------------------------------------------------------------------------------------------------------------------------------------|---------------|
| `PORT`     | The port of the Web UI for the main instance. Since you can map this to any port on the host, there's hardly a reason to change it.                     | `8080`        |
| `USERNAME` | The username of the admin user created on first boot.                                                                                                   | `admin`       |
| `PASSWORD` | The password of the admin user. This value is only used when creating the new user. If you use the default value, please change it after first sign-in. | `password`    |

## Volumes

| Mount Point           | Description                                                                                                                                                                                                        |
|-----------------------|--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `/home/amp/.ampdata`  | This volume contains everything AMP needs to run. This includes all your instances, all their game files, the web ui sign-in info, etc. Essentially, without creating this volume, AMP will be wiped on every boot.|

## HTTPS Support

Setting up HTTPS is independent of the Docker image. Just follow this [official guide](https://github.com/CubeCoders/AMP/wiki/Setting-up-HTTPS-with-AMP) 
and when it tells you to access `/home/AMP/.ampdata`, access the volume you mapped on the host instead. It has the same contents.
To restart the AMP instances, just restart the Docker container.

Or, just put [CloudFlare](https://www.cloudflare.com/) and its free SSL cert in front of your web UI and save yourself hours of pain.

# Support and Contributing

I am a full time college student and have very little time. Still, if you need help, post an issue in the repo and 
work as a community to help each other out. I welcome pull requests if you discuss the changes in an issue first.

Thank you for your help! Enjoy :)
