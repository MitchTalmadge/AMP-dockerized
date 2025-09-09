GHCR Examples
=============

The `docker-compose-ghcr.yml` files in these example directories demonstrate using the GitHub Container Registry (GHCR) alternative instead of Docker Hub.

These configurations are functionally identical to the standard `docker-compose.yml` examples but use:
- `ghcr.io/mitchtalamadge/amp-dockerized:latest` instead of `mitchtalmadge/amp-dockerized:latest`

Both registries contain identical images. Choose the one that works best for your environment.

## Usage

```bash
# Use GHCR instead of Docker Hub
docker compose -f docker-compose-ghcr.yml up -d
```

For detailed setup instructions, please refer to the main README.md file.