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

The container exposes an SSH server on port `22` and a web terminal on port
`7681`. Map these ports when starting the container. With the included
`docker-compose.yml` the mappings are:

```yaml
  - "2222:22"      # SSH
  - "7681:7681"    # ttyd web terminal
```

The default credentials for the web terminal are `terminal` / `terminal`. You
can override them by setting the `TTYD_USER` and `TTYD_PASSWORD` environment
variables.

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

### Root sandbox restrictions

The desktop session now runs as the `devuser` account by default. Some
Electron-based apps still require the `--no-sandbox` flag when executed as
root (for example via `sudo`). The setup scripts automatically patch their
desktop entries so they launch correctly.

## Default root password

The Docker image sets the root password to `ComplexP@ssw0rd!` for convenience
when accessing a shell or VNC session. You can override this and other account
credentials at runtime by setting environment variables in
`docker-compose.yml`:

```yaml
environment:
  DEV_USERNAME: devuser
  DEV_PASSWORD: DevPassw0rd!
  ADMIN_USERNAME: adminuser
  ADMIN_PASSWORD: AdminPassw0rd!
  ROOT_PASSWORD: ComplexP@ssw0rd!
  DEV_UID: 1000
  DEV_GID: 1000
```

These variables control the usernames, passwords and numeric IDs for the
non-root accounts created by the entrypoint script.

## Administrator account

An additional user named `adminuser` has sudo privileges. The default password
is `AdminPassw0rd!`.

## Default user account

A standard user named `devuser` is available with password `DevPassw0rd!`. Use
this account for regular logins instead of `root`.
### User management inside KDE
Supervisor launches `dbus-daemon`, `accounts-daemon` and `polkitd` so the **Users** panel in System Settings can list and manage accounts.


## Pre-installed applications

The image comes with a wide selection of productivity, creative and
development tools pre-installed so you can get started immediately. Highlights
include:

- Office suites: LibreOffice, OnlyOffice and WPS Office
- Web browsers: Google Chrome, Brave, Opera and Firefox
- Development tools: VS Code, Node.js, npm, Docker, Docker Compose, Git,
  MySQL Workbench and DBeaver
- Graphics applications: GIMP, Inkscape, Krita, Blender and Darktable
- Utilities: Flameshot, KDE Connect, Timeshift, Syncthing, OBS Studio and
  Calibre
- Collaboration: Wire, Element, Signal and Nextcloud
- System tools: GNOME Tweaks, Stacer, Neofetch, Btop and AppImage support
- Virtualization and emulators: Waydroid, Anbox, Wine, Bottles, PlayOnLinux,
  WinApps for Linux, QEMU (headless), DOSBox, GNOME Terminal,
  Konsole, LXTerminal, Terminator and Android Studio (without AVD)

These applications are installed automatically when the container is built.

