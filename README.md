# Ubuntu KDE Webtop

This repository builds a Docker container running the KDE desktop environment exposed over VNC.

## Requirements
- Docker Engine
- Docker Compose (v1.x or v2 via the `docker-compose` plugin)

Install `docker-compose` if the command is missing. On Ubuntu:
```bash
sudo apt-get update && sudo apt-get install -y docker-compose
```

## Usage
Run the container using `docker-compose`:
```bash
docker-compose up -d
```
You can validate the configuration with:
```bash
docker-compose config
```

