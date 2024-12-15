#!/bin/bash

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

error() {
    echo -e "${RED}Error: $1${NC}" >&2
    exit 1
}

success() {
    echo -e "${GREEN}$1${NC}"
}

warning() {
    echo -e "${YELLOW}Warning: $1${NC}"
}

main() {

    if [ "$EUID" -ne 0 ]
    then echo "Please run as root"
        exit
    fi

    if grep -q fedora /etc/*-release
    then echo "fedora found"
    else echo "not a fedora machine"
        exit
    fi

    cd "$(dirname "$0")" || error

    dnf install https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

    dnf group update core -y
    dnf4 group update core -y

    dnf update -y

    fwupdmgr refresh --force
    fwupdmgr get-devices
    fwupdmgr get-updates
    fwupdmgr update

    dnf swap 'ffmpeg-free' 'ffmpeg' --allowerasing
    dnf4 group upgrade multimedia
    dnf update @multimedia --setopt="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin
    dnf update @sound-and-video


    dnf install ffmpeg-libs libva libva-utils

    dnf install -y openh264 gstreamer1-plugin-openh264 mozilla-openh264
    dnf config-manager setopt fedora-cisco-openh264.enabled=1

    hostnamectl set-hostname feddy

    systemctl disable NetworkManager-wait-online.service
    rm /etc/xdg/autostart/org.gnome.Software.desktop

    dnf install -y gh stow nvim unzip gammastep fzf ripgrep zoxide nodejs
    dnf4 group install "development tools" "c development tools and libraries" "videolan client"

    curl -fsSL https://bun.sh/install | bash
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh

    success "install completed successfully!"
}

main
