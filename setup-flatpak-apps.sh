#!/bin/bash
set -euxo pipefail

apps=(
    "com.bitwarden.desktop"
    "com.adobe.Reader"
    "com.bluemail.BlueMail"
    "com.simplenote.Simplenote"
    "com.blackmagicdesign.resolve"
    "com.github.phase1geo.minder"
    "org.onlyoffice.desktopeditors"
    "com.wps.Office"
    "io.gitkraken.GitKraken"
    "com.getpostman.Postman"
    "com.obsproject.Studio"
    "com.calibre_ebook.calibre"
    "org.chromium.Chromium"
    "org.mozilla.firefox"
    "com.usebottles.bottles"
    "org.phoenicis.playonlinux"
)

for app in "${apps[@]}"; do
    if ! flatpak info "$app" > /dev/null 2>&1; then
        flatpak install -y --noninteractive flathub "$app"
    fi
done
