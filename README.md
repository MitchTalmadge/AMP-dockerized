# AMP-dockerized
![Docker Cloud Build Status](https://img.shields.io/docker/cloud/build/mitchtalmadge/amp-dockerized)

This repository bundles [CubeCoders AMP](https://cubecoders.com/AMP) into a Debian-based [Docker image.](https://hub.docker.com/r/mitchtalmadge/amp-dockerized) 
(`mitchtalmadge/amp-dockerized:latest`)

In a nutshell, AMP (Application Management Panel) allows you to manage one or more game servers from a web UI.

*Disclaimer:* I (Mitch Talmadge) did not create AMP and am not associated with CubeCoders. I simply made it work with Docker because
 I hate installing things.
 
# Supported Modules
If you are able to get a module working, please add it to this list and any relevant instructions to our Wiki.

If you are *not* able to get a module working, make an issue and we can work together to figure out a solution.

**Tested and Working:**

 - Minecraft Module
 - McMyAdmin Module
 
 **Untested:**
 
- [Everything Else](https://github.com/CubeCoders/AMP/wiki/Supported-Applications-Compatibility)

# Configuration

I recommend using Docker Compose to set up the image. Sample configurations are provided for each 
module in the `example-configs` directory in the [GitHub repo](https://github.com/MitchTalmadge/AMP-dockerized).

## Environment Variables

### User/Group
- `UID` 
  - The ID of the user (on the host) who will own the `/ampdata` volume.
  - Default: `1000`
- `GID` 
  - The ID of the group for the user above.
  - Default: `1000`

When not specified, these both default to ID `1000`; i.e. the first non-system user on the host.

### Licence
- `LICENCE` 
  - The licence key for CubeCoders AMP. You can retrieve or buy this on [their website.](https://manage.cubecoders.com/)
  - No Default. AMP will not boot without a real licence.

**Important Details:**
- _Americans:_ This is spelled licenCe not licenSe. Blame Europe.
- When a McMyAdmin licence is provided, the one and only instance will be a Minecraft instance. This cannot be overridden;
 you must buy a new license to use AMP with other/multiple games.
 
### Web UI
- `PORT` 
  - The port of the Web UI for the main instance. Since you can map this to any port on the 
host, there's hardly a reason to change it.
  - Default: `8080`
- `USERNAME` 
  - The username of the admin user created on first boot. 
  - Default: `admin`
- `PASSWORD` 
  - The password of the admin user. This value is only used when creating the new user. Definitely change this after signing in.
  - Default: `password`

## Volumes

- `/ampdata` 
  - This volume contains everything AMP needs to run. This includes all your instances, all their game files, 
  the web ui sign-in info, etc. Essentially, without creating this volume, AMP will be wiped on every boot.
  - Inside the container, this is linked to `/home/amp/.ampdata`. Just in case you were curious.

# Support and Contributing

I am a full time college student and have very little time. Still, if you need help, post an issue in the repo and 
work as a community to help each other out. I welcome pull requests if you discuss the changes in an issue first.

Thank you for your help! Enjoy :)
