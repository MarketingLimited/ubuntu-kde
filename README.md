# Ubuntu KDE Webtop

This repository builds a Docker container running the KDE desktop environment exposed over VNC.

## Requirements
- Docker Engine
- Docker Compose v2

Install the Docker Compose v2 plugin if `docker compose` is missing. On Ubuntu:
```bash
sudo apt-get update && sudo apt-get install -y docker-compose-v2
```

## Usage
Run the container using `docker compose`:
```bash
docker compose up -d
```
You can validate the configuration with:
```bash
docker compose config
```

If you see warnings from Supervisor about missing configuration, ensure it runs
with the provided config file. The Dockerfile already launches it with:
`supervisord -c /etc/supervisor/supervisord.conf -n`.

## `webtop.sh` helper script

The repository provides `webtop.sh` for common container operations:

```bash
./webtop.sh build   # Build the image
./webtop.sh up      # Start the container
./webtop.sh logs    # Follow container logs
./webtop.sh shell   # Open an interactive shell
```

Run `./webtop.sh help` to see all available commands.

