# Ubuntu KDE Webtop

This repository builds a Docker container running the KDE desktop environment
exposed over VNC and Xpra.

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
The container must run with elevated privileges so PolicyKit and other
components can start correctly. The provided `docker-compose.yml` already
includes `privileged: true`. If you run the image manually, add either
`--privileged` or `--security-opt seccomp=unconfined` to your `docker run`
command.
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
  - "32768:80"    # noVNC web interface
  - "14500:14500"  # Xpra HTML5 client
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

`webtop.sh` checks that `docker-compose.yml` enables privileged mode and warns
if it does not. Running without privileges can prevent PolicyKit and other
services from starting correctly.

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

If the container fails to start with repeated `groupadd: GID '1000' already
exists` or `useradd: UID '1000' is not unique` messages, another group or user
on the system is already using that numeric identifier. Adjust `DEV_GID` (and
optionally `DEV_UID`) in `docker-compose.yml` to unused values so the accounts
can be created successfully.

## Administrator account

An additional user named `adminuser` has sudo privileges. The default password
is `AdminPassw0rd!`. The `devuser` account also belongs to the `sudo` group so
it can perform administrative tasks.

## Default user account

A user named `devuser` is available with password `DevPassw0rd!`. It is part of
the `sudo` group, so you can perform administrator actions without switching
accounts. Use this account for regular logins instead of `root`.
### User management inside KDE
The entrypoint script ensures `dbus-daemon` and `accounts-daemon` are running
when systemd is unavailable. `polkitd` is managed by Supervisor so the **Users**
panel in System Settings can list and manage accounts.
An additional PolicyKit rule grants the `devuser` account permission to perform
privileged actions without authentication, allowing changes through the Users
panel without entering a password.

## Troubleshooting PolicyKit startup

In some environments the `polkitd` binary lives under `/usr/libexec` instead of
`/usr/lib`. Earlier versions of the container hard-coded the path in
`supervisord.conf`, which prevented the daemon from starting when the binary was
elsewhere. The supervisor configuration now launches `polkitd` via the shell and
checks both locations. `entrypoint.sh` also includes a fallback that spawns
`polkitd` manually if no running process is detected.

To confirm it is running inside the container:

```bash
docker compose exec webtop pgrep -a polkitd
```

If nothing is printed, start the daemon manually using one of:

```bash
/usr/lib/policykit-1/polkitd --no-debug &
# or
/usr/libexec/policykit-1/polkitd --no-debug &
```

If `polkitd` repeatedly fails to start with messages like `Operation not
permitted`, your container may be running without enough privileges. In that
case start it in **privileged** mode or disable the default seccomp profile so
PolicyKit can initialize correctly. When using Docker Compose add:

```yaml
services:
  webtop:
    privileged: true
```

Alternatively specify `--security-opt seccomp=unconfined` when running the
container.

### VNC server fails to start

If `Xvnc` quickly enters a *FATAL* state or you cannot connect over VNC, check
the container logs using `docker compose logs webtop`. The server sometimes
cannot access required system resources when the container runs with a
restricted security profile. Launching the container in **privileged** mode or
with `--security-opt seccomp=unconfined` usually resolves the issue.

### Running Waydroid inside the container

Waydroid relies on the `binder` and `ashmem` kernel modules. Load them on the
host before starting the container:

```bash
sudo modprobe binder_linux
sudo modprobe ashmem_linux   # optional on newer kernels
```

Start the container in privileged mode and pass the binder filesystem from the
host:

```bash
docker run -d --name webtop-kde \
  --privileged \
  -v /dev/binderfs:/dev/binderfs \
  -p 32768:80 -p 2222:22 -p 7681:7681 \
  -p 14500:14500 \
  webtop-kde:latest
```

Inside the container initialize Waydroid once:

```bash
waydroid init
waydroid session start
```

## Audio support

The container runs a PulseAudio server so graphical applications can output sound.
Ensure the host's sound device is passed through by mapping `/dev/snd` when
running the container. The included `docker-compose.yml` already exposes this
device.

If your host does not provide a real sound card you can load the Linux
`snd-dummy` module to create a virtual one before starting the container:

```bash
sudo modprobe snd-dummy
```

After the module is loaded restart the container so `/dev/snd` appears inside
it and PulseAudio can output audio.

noVNC itself only handles the graphical display and does not forward sound to
the browser. This image now includes **Xpra**, which starts automatically and
provides an HTML5 client on port `14500`. Connect to this port in your browser
to access the desktop with working audio. The noVNC interface on port `80`
remains available as a fallback.

## Software rendering via Mesa llvmpipe

Mesa's software rasterizer packages are installed in the image so GPU-heavy
applications can run even without dedicated graphics hardware. Verify the
active renderer with:

```bash
glxinfo | grep "OpenGL renderer"
```

The output should mention **llvmpipe**, confirming Mesa's CPU-based rendering is
in use.


## Pre-installed applications

The image comes with a wide selection of productivity, creative and
development tools pre-installed so you can get started immediately. Highlights
include:

- Office suites: LibreOffice, OnlyOffice and WPS Office
- Web browsers: Google Chrome, Brave, Opera and Firefox
- Development tools: VS Code, Node.js 20 (via NodeSource), npm, Docker, Docker Compose, Git,
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

