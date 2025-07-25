#!/bin/bash
set -euo pipefail

apps=(
    "com.bitwarden.desktop"
    "com.adobe.Reader"
    "com.bluemail.BlueMail"
    "com.simplenote.Simplenote"
    "com.blackmagicdesign.resolve"
    "com.github.phase1geo.minder"
)

for app in "${apps[@]}"; do
    if ! flatpak info "$app" > /dev/null 2>&1; then
        flatpak install -y --noninteractive flathub "$app"
    fi
done
