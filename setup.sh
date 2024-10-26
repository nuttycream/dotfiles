#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Print error message and exit
error() {
    echo -e "${RED}Error: $1${NC}" >&2
    exit 1
}

# Print success message
success() {
    echo -e "${GREEN}$1${NC}"
}

# Print warning message
warning() {
    echo -e "${YELLOW}Warning: $1${NC}"
}

# Check if stow is installed
check_stow() {
    if ! command -v stow &> /dev/null; then
        error "GNU Stow is not installed. Please install it first."
    fi
}

# Backup existing files
backup_existing() {
    local backup_dir="$HOME/.dotfiles_backup/$(date +%Y%m%d_%H%M%S)"
    local needs_backup=false

    # Find all dotfiles in our repository
    while IFS= read -r file; do
        # Convert the path to its target location in $HOME
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

# Create symbolic links using stow
stow_dotfiles() {
    # Find all directories that aren't hidden or special
    local packages=$(find . -maxdepth 1 -type d -not -name ".*" -not -name "__*" -printf "%f\n" | grep -v '^$')

    for package in $packages; do
        if [ -d "$package" ]; then
            # Use --no-folding to prevent stow from creating parent directories
            stow --no-folding -t "$HOME" -R "$package" || error "Failed to stow $package"
            success "Stowed $package successfully"
        else
            warning "Package $package not found, skipping"
        fi
    done
}

main() {
    # Change to the script's directory
    cd "$(dirname "$0")" || error "Failed to change to script directory"

    check_stow
    backup_existing
    stow_dotfiles

    success "Dotfiles setup completed successfully!"
}

main
