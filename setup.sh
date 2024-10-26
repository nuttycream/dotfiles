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

check_stow() {
    if ! command -v stow &> /dev/null; then
        error "GNU Stow is not installed. Please install it first."
    fi
}

backup_existing() {
    local backup_dir="$HOME/.dotfiles_backup/$(date +%Y%m%d_%H%M%S)"
    local needs_backup=false

    while IFS= read -r file; do
        local target_file="$HOME/${file#*/}"
        if [ -e "$target_file" ]; then
            needs_backup=true
            break
        fi
    done < <(find . -type f -not -path "*/.git/*")

    if [ "$needs_backup" = true ]; then
        mkdir -p "$backup_dir"
        while IFS= read -r file; do
            local target_file="$HOME/${file#*/}"
            if [ -e "$target_file" ]; then
                local backup_path="$backup_dir$(dirname "${file#*/}")"
                mkdir -p "$backup_path"
                cp -a "$target_file" "$backup_path/"
                success "Backed up $target_file to $backup_path/"
            fi
        done < <(find . -type f -not -path "*/.git/*")
    fi
}

stow_dotfiles() {
    local packages=$(find . -maxdepth 1 -type d -not -name ".*" -not -name "__*" -printf "%f\n" | grep -v '^$')

    for package in $packages; do
        if [ -d "$package" ]; then
            # use --no-folding to prevent stow from creating parent directories
            stow --no-folding -t "$HOME" -R "$package" || error "Failed to stow $package"
            success "Stowed $package successfully"
        else
            warning "Package $package not found, skipping"
        fi
    done
}

main() {
    cd "$(dirname "$0")" || error "Failed to change to script directory"

    check_stow
    backup_existing
    stow_dotfiles

    success "Dotfiles setup completed successfully!"
}

main
