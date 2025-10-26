# Copilot Instructions for AMP-dockerized

## Repository Overview

**AMP-dockerized** is a community-maintained, unofficial Docker image for [CubeCoders AMP](https://cubecoders.com/AMP) (Application Management Panel) - a web-based game server management system. This repository creates a Debian-based Docker container that allows users to manage multiple game servers through AMP's web interface.

**Key Facts:**
- **Size:** Small repository (~30 files, ~600 lines total)
- **Primary Technologies:** Docker, Bash shell scripts, YAML configs
- **Target Runtime:** Docker containers running on Linux
- **License:** MIT (repository code), CubeCoders license (AMP software)
- **Status:** Community-driven, unofficial, unsupported by CubeCoders

## Build and Validation

### Primary Build Process
The main and only build process is Docker image creation:

```bash
docker build -t amp-dockerized:test .
```

**Important Build Constraints:**
- **Build Time:** 10-15+ minutes due to large package downloads (Java JDKs, game server dependencies)
- **Network Dependencies:** Requires internet connectivity for downloading:
  - Adoptium JDK packages (Java 8, 11, 17, 21, 25)
  - CubeCoders AMP installer
  - Debian packages and Wine dependencies
- **Architecture Support:** Builds for linux/amd64 and linux/arm64
- **Memory Requirements:** Can be memory-intensive during package installation

**Known Build Issues:**
- Build timeouts: Always use timeout values of 600+ seconds for Docker builds

### Build Command Sequence
```bash
# Standard build (use 10+ minute timeout)
docker build -t amp-dockerized:latest .

# Multi-platform build (as used in CI)
docker build --platform linux/amd64,linux/arm64 -t amp-dockerized:latest .
```

### Validation Steps
Since this is a Docker-only project, validation occurs through:

1. **Successful Docker Build** - Primary validation method
2. **Container Startup Test**:
```bash
docker run -p 8080:8080 amp-dockerized:latest
```
3. **Shell Script Syntax Check**:
```bash
find entrypoint -name "*.sh" | xargs shellcheck
```

**No Traditional Testing:** This repository has no unit tests, integration tests, or automated test suites.

## GitHub Actions CI/CD Pipeline

The repository uses GitHub Actions for continuous integration:

**Workflows:**
- `.github/workflows/build.yml` - Builds Docker images for both architectures on PRs and workflow calls
- `.github/workflows/deploy-prod.yml` - Deploys to Docker Hub on master branch pushes and tags
- `.github/workflows/deploy-staging.yml` - Staging deployments
- `.github/workflows/codeql.yml` - CodeQL security analysis

**Trigger Paths:** Changes to `Dockerfile`, `.dockerignore`, `entrypoint/**`, or `.github/workflows/**` trigger builds

**Deployment:** Automatic deployment to Docker Hub (`mitchtalmadge/amp-dockerized`) on master branch

## Project Architecture and Layout

### Core Structure
```
/
├── Dockerfile              # Main Docker image definition
├── entrypoint/             # Container initialization scripts
│   ├── main.sh            # Primary entrypoint
│   ├── routines.sh        # AMP configuration routines
│   └── utils.sh           # Utility functions
├── example-configs/        # Docker Compose examples for different games
│   ├── ads/               # ADS (multi-server) configuration
│   ├── minecraft/         # Minecraft server
│   ├── factorio/          # Factorio server
│   └── [others]           # Various game server configs
└── .github/workflows/     # GitHub Actions CI/CD
```

### Key Configuration Files
- **Dockerfile:** Multi-stage build with Java, Mono, Wine, and game dependencies
- **entrypoint/main.sh:** Container startup sequence, error handling, signal traps
- **entrypoint/routines.sh:** AMP instance management, license validation, user creation
- **entrypoint/utils.sh:** AMP command execution helpers, progress bar handling

### Environment Variables (Default Configuration)
```bash
# Core container settings
UID=1000, GID=1000, TZ=Etc/UTC, PORT=8080, USERNAME=admin, PASSWORD=password, IPBINDING=0.0.0.0

# AMP-specific settings  
AMP_AUTO_UPDATE=true, AMP_RELEASE_STREAM=Mainline, AMP_SUPPORT_LEVEL=UNSUPPORTED
```

### Dependencies and Architecture
- **Base Image:** `debian:13-slim`
- **Runtime Requirements:** Java JDKs (8,11,17,21,25), Mono, Wine, various game server dependencies
- **AMP Installation:** Manual extraction from `.deb` package (not using package manager due to Docker limitations)
- **Volume Mount:** `/home/amp/.ampdata` for persistent game server data
- **Network Requirements:** Container needs internet access for AMP updates and game server downloads

### Entry Point Execution Flow
1. **main.sh:** Signal handling, environment setup, routine execution
2. **User creation:** Creates `amp` user with specified UID/GID
3. **Permission setup:** Sets ownership of `/home/amp` directory
4. **AMP configuration:** Creates main instance if needed, configures release stream
5. **Service startup:** Launches AMP and monitoring processes

### Common File Operations
- **Configuration changes:** Modify environment variables in Docker Compose files
- **Script modifications:** Edit files in `entrypoint/` directory
- **New game support:** Add example configs in `example-configs/[game]/`
- **Dockerfile updates:** Usually for base image changes or dependency updates

### Critical Integration Points
- **MAC Address Requirement:** Docker containers must have static MAC addresses to prevent AMP license resets
- **Port Mapping:** Game-specific ports must be exposed in container configuration
- **Volume Persistence:** AMP data must be mounted to host filesystem for persistence

## Key Development Patterns

**Shell Script Conventions:**
- Error handling with `set -e` and custom `handle_error` function
- Progress bar filtering for AMP command output
- Silent command execution for background tasks

**Docker Best Practices:**
- Multi-stage package installations with cleanup
- Non-interactive package installation (`DEBIAN_FRONTEND=noninteractive`)
- Layer optimization with combined RUN statements

**Debugging Notes:**
- AMP logs available at `ampdata/instances/Main/AMP_Logs`
- Container logs show startup sequence and errors
- Use `docker exec -it <container> bash` for troubleshooting

## Agent Instructions

**Trust These Instructions:** Only search for additional information if these instructions are incomplete or proven incorrect. This repository structure is well-documented above.

**For Build Issues:**
1. Always use 600+ second timeouts for Docker builds
2. Check network connectivity to `packages.adoptium.net`

**For Code Changes:**
1. Test shell scripts with `shellcheck` before committing
2. Validate Docker builds locally before pushing
3. Be aware that changes trigger CI builds that take 10+ minutes
4. Respect the community-maintained nature - changes should be minimal and well-tested

**For Configuration:**
1. Most user-facing changes involve example Docker Compose files
2. Script changes require understanding of AMP command structure
3. Environment variable changes need documentation updates in README.md