#!/bin/bash
set -e

# Default credentials and IDs can be overridden via environment variables
DEV_USERNAME=${DEV_USERNAME:-devuser}
DEV_PASSWORD=${DEV_PASSWORD:-DevPassw0rd!}
DEV_UID=${DEV_UID:-1000}
DEV_GID=${DEV_GID:-1000}
ADMIN_USERNAME=${ADMIN_USERNAME:-adminuser}
ADMIN_PASSWORD=${ADMIN_PASSWORD:-AdminPassw0rd!}
ROOT_PASSWORD=${ROOT_PASSWORD:-ComplexP@ssw0rd!}

# Update root password if provided
if [ -n "$ROOT_PASSWORD" ]; then
    echo "root:${ROOT_PASSWORD}" | chpasswd
fi

# Ensure polkitd system user and group exist
getent group polkitd >/dev/null || groupadd -r polkitd
getent passwd polkitd >/dev/null || useradd -r -g polkitd -s /sbin/nologin polkitd

# Apply required capabilities and permissions for PolicyKit
if command -v setcap >/dev/null 2>&1; then
    setcap cap_setgid=pe /usr/lib/polkit-1/polkitd || true
fi
chmod 4755 /usr/lib/policykit-1/polkit-agent-helper-1

# Ensure group and user exist
if ! getent group "$DEV_USERNAME" > /dev/null; then
    groupadd -g "$DEV_GID" "$DEV_USERNAME"
fi

# Ensure the ssl-cert group exists for adding the dev user
if ! getent group ssl-cert > /dev/null; then
    groupadd ssl-cert
fi

if ! id -u "$DEV_USERNAME" > /dev/null 2>&1; then
    useradd -m -s /bin/bash -u "$DEV_UID" -g "$DEV_GID" "$DEV_USERNAME"
fi

echo "${DEV_USERNAME}:${DEV_PASSWORD}" | chpasswd
usermod -aG sudo,ssl-cert,pulse-access,video "$DEV_USERNAME"

# Admin user
if ! id -u "$ADMIN_USERNAME" > /dev/null 2>&1; then
    useradd -m -s /bin/bash "$ADMIN_USERNAME"
fi

echo "${ADMIN_USERNAME}:${ADMIN_PASSWORD}" | chpasswd
usermod -aG sudo "$ADMIN_USERNAME"

sed -i 's/^%sudo.*/%sudo ALL=(ALL) NOPASSWD:ALL/' /etc/sudoers

# Prepare VNC startup script for dev user
mkdir -p "/home/${DEV_USERNAME}/.vnc"
cat <<'XEOF' > "/home/${DEV_USERNAME}/.vnc/xstartup"
#!/bin/sh
export XKL_XMODMAP_DISABLE=1
exec dbus-launch --exit-with-session startplasma-x11
XEOF
chown -R "${DEV_USERNAME}":"${DEV_USERNAME}" "/home/${DEV_USERNAME}/.vnc"
chmod +x "/home/${DEV_USERNAME}/.vnc/xstartup"

# XDG runtime directory
mkdir -p "/run/user/${DEV_UID}"
chown "${DEV_USERNAME}":"${DEV_USERNAME}" "/run/user/${DEV_UID}"
chmod 700 "/run/user/${DEV_UID}"
export XDG_RUNTIME_DIR="/run/user/${DEV_UID}"

# Register user with AccountsService

# Ensure the system D-Bus is available before using dbus-send
if [ ! -S /run/dbus/system_bus_socket ]; then
    mkdir -p /run/dbus
    if command -v dbus-daemon >/dev/null 2>&1; then
        dbus-daemon --system --fork || true
        for _ in {1..10}; do
            [ -S /run/dbus/system_bus_socket ] && break
            sleep 0.5
        done
    else
        echo "dbus-daemon not found; skipping system bus start"
    fi
fi

if command -v dbus-send >/dev/null 2>&1; then
    dbus-send --system --dest=org.freedesktop.Accounts --type=method_call \
      /org/freedesktop/Accounts org.freedesktop.Accounts.CacheUser string:"${DEV_USERNAME}" || true
else
    echo "dbus-send not found; skipping AccountsService registration"
fi
if [ -f "/var/lib/AccountsService/users/${DEV_USERNAME}" ]; then
    if ! grep -q '^SystemAccount=false' "/var/lib/AccountsService/users/${DEV_USERNAME}"; then
        echo 'SystemAccount=false' >> "/var/lib/AccountsService/users/${DEV_USERNAME}"
    fi
fi

# Launch accounts-daemon manually when systemd services are unavailable
if command -v systemctl >/dev/null 2>&1 && [ "$(ps -p 1 -o comm=)" = systemd ]; then
    systemctl restart accounts-daemon || true
else
    if pgrep -x accounts-daemon >/dev/null 2>&1; then
        killall accounts-daemon || true
    fi
    started=false
    for path in \
        /usr/lib/accountsservice/accounts-daemon \
        /usr/sbin/accounts-daemon \
        /usr/libexec/accounts-daemon \
        $(command -v accounts-daemon 2>/dev/null); do
        if [ -x "$path" ]; then
            echo "Starting accounts-daemon at $path"
            "$path" &
            started=true
            break
        fi
    done
    if [ "$started" = false ]; then
        echo "accounts-daemon not available; skipping"
    fi
fi


# Fix permissions so KDE apps can write files
chown -R devuser:devuser /home/devuser
chown -R adminuser:adminuser /home/adminuser

# Fallback: Start polkitd manually if supervisor fails
if ! pgrep polkitd >/dev/null; then
  echo "Starting fallback polkitd..."
  if [ -x /usr/libexec/policykit-1/polkitd ]; then
    /usr/libexec/policykit-1/polkitd --no-debug &
  elif [ -x /usr/lib/policykit-1/polkitd ]; then
    /usr/lib/policykit-1/polkitd --no-debug &
  elif [ -x /usr/lib/polkit-1/polkitd ]; then
    /usr/lib/polkit-1/polkitd --no-debug &
  fi
fi

exec env \
    ENV_DEV_USERNAME="${DEV_USERNAME}" \
    ENV_DEV_UID="${DEV_UID}" \
    DEV_USERNAME="${DEV_USERNAME}" DEV_UID="${DEV_UID}" \
    /usr/bin/supervisord -c /etc/supervisor/supervisord.conf -n
