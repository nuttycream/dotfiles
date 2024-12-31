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

setup_dotfiles() {
    if [ -f "./setup.sh" ]; then
        chmod +x ./setup.sh
        su - $SUDO_USER -c "cd $PWD && ./setup.sh"
        success "Dotfiles setup completed"
    else
        warning "setup.sh not found in current directory"
    fi
}

main() {
    if [ "$EUID" -ne 0 ]; then
        error "Please run as root"
    fi

    if ! grep -q fedora /etc/*-release; then
        error "Not a Fedora machine"
    fi

    cd "$(dirname "$0")" || error "Failed to change directory"

    dnf install -y https://mirrors.rpmfusion.org/free/fedora/rpmfusion-free-release-$(rpm -E %fedora).noarch.rpm \
        https://mirrors.rpmfusion.org/nonfree/fedora/rpmfusion-nonfree-release-$(rpm -E %fedora).noarch.rpm

    dnf group update core -y
    dnf4 group update core -y
    dnf update -y

    fwupdmgr refresh --force
    fwupdmgr get-devices
    fwupdmgr get-updates
    fwupdmgr update

    dnf swap 'ffmpeg-free' 'ffmpeg' --allowerasing -y
    dnf4 group upgrade multimedia -y
    dnf update @multimedia --setopt="install_weak_deps=False" --exclude=PackageKit-gstreamer-plugin -y
    dnf update @sound-and-video -y
    dnf install -y ffmpeg-libs libva libva-utils
    dnf install -y openh264 gstreamer1-plugin-openh264 mozilla-openh264
    dnf config-manager --setopt=fedora-cisco-openh264.enabled=1

    hostnamectl set-hostname feddy
    systemctl disable NetworkManager-wait-online.service
    rm -f /etc/xdg/autostart/org.gnome.Software.desktop

    dnf install -y gh stow nvim unzip gammastep fzf ripgrep zoxide nodejs golang
    dnf4 group install -y "Development Tools" "C Development Tools and Libraries" "VLC media player"

    su - $SUDO_USER -c 'curl -fsSL https://bun.sh/install | bash'
    su - $SUDO_USER -c 'curl --proto "=https" --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y'

    setup_dotfiles
    fc-cache -v

    success "install and config completed successfully"
}

main
