FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

# Install all required packages and lightweight fallback WM
RUN apt-get update && apt-get install -y \
    sudo wget curl gnupg2 apt-transport-https software-properties-common \
    ca-certificates lsb-release htop net-tools unzip locales \
    kde-plasma-desktop dolphin kate okular konsole \
    openbox tint2 xterm \
    firefox libreoffice vlc gimp inkscape shutter winff kodi plank \
    flatpak gnome-software-plugin-flatpak \
    fonts-noto-core fonts-noto-ui-core fonts-noto-color-emoji fonts-noto-extra \
    fonts-dejavu fonts-crosextra-carlito fonts-crosextra-caladea fonts-hosny-amiri fonts-kacst qttranslations5-l10n libqt5script5 fonts-freefont-ttf \
    supervisor tigervnc-standalone-server tigervnc-common novnc websockify \
    dbus-x11 x11-xserver-utils xfonts-base \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Add repositories for Chrome, Opera, Brave, VS Code
RUN wget -qO- https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor > /usr/share/keyrings/packages.microsoft.gpg \
    && echo "deb [arch=amd64 signed-by=/usr/share/keyrings/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" > /etc/apt/sources.list.d/vscode.list \
    && curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg arch=amd64] https://brave-browser-apt-release.s3.brave.com/ stable main" > /etc/apt/sources.list.d/brave-browser-release.list \
    && wget -qO- https://deb.opera.com/archive.key | gpg --dearmor > /usr/share/keyrings/opera.gpg \
    && echo "deb [arch=amd64 signed-by=/usr/share/keyrings/opera.gpg] https://deb.opera.com/opera-stable/ stable non-free" > /etc/apt/sources.list.d/opera.list \
    && apt-get update

# Install browsers and editors
RUN mkdir -p /etc/apt/keyrings \
    && wget -q -O - https://dl.google.com/linux/linux_signing_key.pub | gpg --dearmor | tee /etc/apt/keyrings/google-chrome.gpg > /dev/null \
    && echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/google-chrome.gpg] http://dl.google.com/linux/chrome/deb/ stable main" > /etc/apt/sources.list.d/google-chrome.list \
    && apt-get update \
    && apt-get install -y \
        google-chrome-stable brave-browser opera-stable code \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

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

EXPOSE 80 5901

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/supervisord.conf", "-n"]
