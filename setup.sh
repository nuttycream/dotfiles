#!/bin/bash

GREEN='\033[0;32m'
NC='\033[0m'

backup_dir="$HOME/.dotfiles_backup/$(date +%Y%m%d_%H%M%S)"

if ! command -v stow &> /dev/null; then
    echo "Error: gnu stow is not installed" >&2
    exit 1
fi

cd "$(dirname "$0")" || exit 1

for dir in */; do
    if [ -d "$dir" ] && [[ ! "$dir" =~ ^(\.|__) ]]; then
        pkg=${dir%/}

        while IFS= read -r file; do
            target="$HOME/${file#*/}"
            if [ -e "$target" ]; then
                backup_path="$backup_dir$(dirname "${file#*/}")"
                mkdir -p "$backup_path"
                cp -a "$target" "$backup_path/"
                echo -e "${GREEN}backed up: $target${NC}"
                rm "$target"
                echo -e "${GREEN}rmd original: $target${NC}"
            fi
        done < <(find "$pkg" -type f)

        stow --no-folding -t "$HOME" -R "$pkg"
        echo -e "${GREEN}Stowed: $pkg${NC}"
    fi
done

echo -e "${GREEN}Dotfiles setup completed${NC}"
