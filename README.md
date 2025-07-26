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

### Root sandbox restrictions

The container runs applications as the `root` user. Electron-based apps like Chrome,
Chromium-based browsers, Electron collaboration tools like Element, Signal and Wire,
and apps such as VS Code and Bitwarden need the `--no-sandbox` flag when
executed as root. The setup scripts automatically patch their desktop entries so
they launch correctly inside the container.

## Default root password

The Docker image sets the root password to `ComplexP@ssw0rd!` for convenience
when accessing a shell or VNC session. Change this in the `Dockerfile` if you
need a different password.

## Administrator account

An additional user named `adminuser` has sudo privileges. The default password
is `AdminPassw0rd!`.

## Default user account

A standard user named `devuser` is available with password `DevPassw0rd!`. Use
this account for regular logins instead of `root`.
### User management inside KDE
The container runs `accounts-daemon` via Supervisor so the **Users** panel in System Settings can list and manage accounts.


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
  WinApps for Linux, QEMU (headless), Darling, DOSBox, GNOME Terminal,
  Konsole, LXTerminal, Terminator and Android Studio (without AVD)

These applications are installed automatically when the container is built.

