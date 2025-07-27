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
mkdir -p /home/${DEV_USERNAME}/.vnc
cat <<'XEOF' > /home/${DEV_USERNAME}/.vnc/xstartup
#!/bin/sh
export XKL_XMODMAP_DISABLE=1
exec dbus-launch --exit-with-session startplasma-x11
XEOF
chown -R ${DEV_USERNAME}:${DEV_USERNAME} /home/${DEV_USERNAME}/.vnc
chmod +x /home/${DEV_USERNAME}/.vnc/xstartup

# XDG runtime directory
mkdir -p /run/user/${DEV_UID}
chown ${DEV_USERNAME}:${DEV_USERNAME} /run/user/${DEV_UID}
chmod 700 /run/user/${DEV_UID}
export XDG_RUNTIME_DIR=/run/user/${DEV_UID}

# Register user with AccountsService

# Ensure the system D-Bus is available before using dbus-send
if [ ! -S /run/dbus/system_bus_socket ]; then
    mkdir -p /run/dbus
    dbus-daemon --system --fork
fi

dbus-send --system --dest=org.freedesktop.Accounts --type=method_call \
  /org/freedesktop/Accounts org.freedesktop.Accounts.CacheUser string:"${DEV_USERNAME}"
if [ -f /var/lib/AccountsService/users/${DEV_USERNAME} ]; then
    if ! grep -q '^SystemAccount=false' /var/lib/AccountsService/users/${DEV_USERNAME}; then
        echo 'SystemAccount=false' >> /var/lib/AccountsService/users/${DEV_USERNAME}
    fi
fi
service accounts-daemon restart

exec sudo -E -u "${DEV_USERNAME}" \
    DEV_USERNAME="${DEV_USERNAME}" DEV_UID="${DEV_UID}" \
    XDG_RUNTIME_DIR="/run/user/${DEV_UID}" \
    /usr/bin/supervisord -c /etc/supervisor/supervisord.conf -n
