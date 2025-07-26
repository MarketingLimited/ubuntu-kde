FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install all required packages and lightweight fallback WM
RUN apt-get update && apt-get install -y \
    sudo wget curl gnupg2 apt-transport-https software-properties-common \
    ca-certificates lsb-release htop net-tools unzip locales \
    kde-plasma-desktop dolphin kate okular konsole \
    openbox tint2 xterm \
    libreoffice vlc gimp inkscape shutter winff kodi plank \
    flatpak gnome-software-plugin-flatpak \
    flameshot kdeconnect timeshift syncthing syncthing-gtk \
    krita blender darktable obs-studio calibre \
    git neofetch btop gnome-tweaks stacer \
    docker.io docker-compose \
    nodejs npm python3 python3-pip jupyter-notebook \
    nextcloud-desktop \
    fonts-noto-core fonts-noto-ui-core fonts-noto-color-emoji fonts-noto-extra \
    fonts-dejavu fonts-crosextra-carlito fonts-crosextra-caladea fonts-hosny-amiri fonts-kacst qttranslations5-l10n libqt5script5 fonts-freefont-ttf \
    supervisor tigervnc-standalone-server tigervnc-common novnc websockify \
    dbus-x11 x11-xserver-utils xfonts-base snapd \
    wine playonlinux qemu-system qemu-utils qemu-kvm \
    dosbox gnome-terminal lxterminal terminator accountsservice \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Add repositories for Chrome, Opera, Brave, VS Code
RUN wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /usr/share/keyrings/packages.microsoft.gpg \
    && echo "deb [arch=amd64 signed-by=/usr/share/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list \
    && curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg arch=amd64] https://brave-browser-apt-release.s3.brave.com/ stable main" > /etc/apt/sources.list.d/brave-browser-release.list \
    && wget -qO- https://deb.opera.com/archive.key | gpg --dearmor > /usr/share/keyrings/opera.gpg \
    && echo "deb [arch=amd64 signed-by=/usr/share/keyrings/opera.gpg] https://deb.opera.com/opera-stable/ stable non-free" > /etc/apt/sources.list.d/opera.list \
    && apt-get update

# Install dbeaver
RUN wget -O /usr/share/keyrings/dbeaver.gpg.key https://dbeaver.io/debs/dbeaver.gpg.key \
    && echo "deb [signed-by=/usr/share/keyrings/dbeaver.gpg.key] https://dbeaver.io/debs/dbeaver-ce /" > /etc/apt/sources.list.d/dbeaver.list \
    && apt-get update && apt-get install -y dbeaver-ce && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install wire-desktop
RUN wget -qO- https://wire-app.wire.com/linux/releases.key | gpg --dearmor > /usr/share/keyrings/wire-desktop.gpg \
    && echo "deb [arch=amd64 signed-by=/usr/share/keyrings/wire-desktop.gpg] https://wire-app.wire.com/linux/debian stable main" > /etc/apt/sources.list.d/wire-desktop.list \
    && apt-get update && apt-get install -y wire-desktop && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install element-desktop
RUN wget -O /usr/share/keyrings/element-io-archive-keyring.gpg https://packages.element.io/debian/element-io-archive-keyring.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/element-io-archive-keyring.gpg] https://packages.element.io/debian/ default main" > /etc/apt/sources.list.d/element-io.list \
    && apt-get update && apt-get install -y element-desktop && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install signal-desktop
RUN wget -O- https://updates.signal.org/desktop/apt/keys.asc | gpg --dearmor > /usr/share/keyrings/signal-desktop-keyring.gpg \
    && echo 'deb [arch=amd64 signed-by=/usr/share/keyrings/signal-desktop-keyring.gpg] https://updates.signal.org/desktop/apt xenial main' > /etc/apt/sources.list.d/signal-xenial.list \
    && apt-get update && apt-get install -y signal-desktop && apt-get clean && rm -rf /var/lib/apt/lists/*

# Install browsers and editors
RUN mkdir -p /etc/apt/keyrings \
    && wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor | tee /etc/apt/keyrings/google-chrome.gpg > /dev/null \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list \
    && apt-get update \
    && apt-get install -y \
        google-chrome-stable brave-browser opera-stable code \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Allow running Chromium-based browsers as root
RUN for f in google-chrome.desktop brave-browser.desktop opera.desktop code.desktop element-desktop.desktop signal-desktop.desktop wire-desktop.desktop; do \
        if [ -f "/usr/share/applications/$f" ]; then \
            sed -i '/^Exec=/ s@ %U@ --no-sandbox %U@; /^Exec=/ s@ %F@ --no-sandbox %F@; /^Exec=/ {/--no-sandbox/! s@$@ --no-sandbox@}' "/usr/share/applications/$f"; \
        fi; \
    done

# Install Waydroid repository and package
RUN curl -fsSL https://repo.waydro.id | bash \
    && apt-get install -y waydroid && apt-get clean && rm -rf /var/lib/apt/lists/*

# Optional Anbox support via snap
RUN snap install anbox --beta --devmode || true

# Install Darling for macOS compatibility
RUN echo "deb [signed-by=/usr/share/keyrings/darling.gpg] https://repo.darlinghq.org/ $(lsb_release -cs) main" > /etc/apt/sources.list.d/darling.list \
    && curl -fsSL https://repo.darlinghq.org/darling.asc | gpg --dearmor -o /usr/share/keyrings/darling.gpg \
    && apt-get update && apt-get install -y darling && apt-get clean && rm -rf /var/lib/apt/lists/*

# Clone WinApps for Linux
RUN git clone https://github.com/Fmstrat/winapps.git /opt/winapps

# Install Android Studio without AVD
RUN snap install android-studio --classic --no-wait || true

# Setup Flatpak remote only
RUN flatpak remote-add --if-not-exists flathub https://flathub.org/repo/flathub.flatpakrepo

# Locales
RUN locale-gen en_US.UTF-8 ar_EG.UTF-8 \
    && update-locale LANG=en_US.UTF-8 LANGUAGE=en_US.UTF-8 LC_ALL=en_US.UTF-8 \
    && fc-cache -f -v

ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# VNC xstartup: launch KDE Plasma
RUN mkdir -p /root/.vnc && \
    echo '#!/bin/sh\n\
export XKL_XMODMAP_DISABLE=1\n\
exec dbus-launch --exit-with-session startplasma-x11' > /root/.vnc/xstartup && \
    chmod +x /root/.vnc/xstartup

# Desktop and Flatpak setup scripts
COPY setup-flatpak-apps.sh /usr/local/bin/setup-flatpak-apps.sh
COPY setup-desktop.sh /usr/local/bin/setup-desktop.sh
RUN chmod +x /usr/local/bin/setup-flatpak-apps.sh /usr/local/bin/setup-desktop.sh

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Set a default root password for interactive logins
RUN echo 'root:ComplexP@ssw0rd!' | chpasswd \
    && useradd -m -s /bin/bash adminuser \
    && echo 'adminuser:AdminPassw0rd!' | chpasswd \
    && usermod -aG sudo adminuser \
    && useradd -m -s /bin/bash devuser \
    && echo 'devuser:DevPassw0rd!' | chpasswd

EXPOSE 80 5901

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf", "-n"]
