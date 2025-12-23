#!/bin/bash

set -e

DOTFILES_DIR="$HOME/.local/share/dotfiles"
REPO_URL="https://github.com/Wuedmo/Dotfiles.git"

echo "=============="
echo "Dotfiles Setup"
echo "=============="
echo

# Check if dotfiles directory already exists
if [ -d "$DOTFILES_DIR" ]; then
    echo "ERROR: $DOTFILES_DIR already exists!"

    # If not running interactively, abort to avoid destructive actions
    if [ ! -t 0 ]; then
        echo "Non-interactive shell detected; aborting to avoid destructive changes."
        exit 1
    fi

    while true; do
        read -p "Choose action: [R]emove, [M]ove to backup, [A]bort (R/M/A): " choice
        case "${choice,,}" in
            r|remove)
                echo "Removing existing directory: $DOTFILES_DIR"
                rm -rf "$DOTFILES_DIR"
                echo "Removed. Continuing installation."
                break
                ;;
            m|move)
                ts=$(date +%Y%m%d_%H%M%S)
                target="$DOTFILES_DIR.backup.$ts"
                echo "Moving $DOTFILES_DIR -> $target"
                mv "$DOTFILES_DIR" "$target"
                echo "Moved to $target. Continuing installation."
                break
                ;;
            a|abort)
                echo "Aborting per user request. No changes made."; exit 1
                ;;
            *)
                echo "Please enter R, M, or A." ;;
        esac
    done
fi

# Check if git is installed
if ! command -v git &> /dev/null; then
    echo "Git is not installed. Installing git..."
    sudo pacman -S --noconfirm git
    echo "Git installed successfully!"
fi

# Create .config directory if it doesn't exist
mkdir -p "$HOME/.config"

# Create .local/share/dotfiles directory
mkdir -p "$HOME/.local/share/dotfiles"

# Clone the dotfiles repository
echo "Cloning dotfiles repository..."
git clone "$REPO_URL" "$DOTFILES_DIR"

echo
echo "Repository cloned successfully!"
echo "Starting installation..."
echo

detect_cachyos() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        case "${ID,,}" in
            cachyos|cachy) return 0 ;;
        esac
        case "${PRETTY_NAME,,}" in
            *cachyos*) return 0 ;;
        esac
    fi
    return 1
}

# Decide installer flags
installer_flags=()

if detect_cachyos; then
    echo "CachyOS detected — will run installer in CachyOS-first mode (skips AUR by default)."
    installer_flags+=("--cachyos")
else
    if [ -t 0 ]; then
        read -p "Run installer in CachyOS mode (prefer repos over AUR)? [y/N]: " yn
        case "${yn,,}" in
            y|yes) installer_flags+=("--cachyos") ;;
        esac
    fi
fi

if [ -t 0 ]; then
    read -p "Perform a dry-run first (show actions only)? [y/N]: " dr
    case "${dr,,}" in
        y|yes) installer_flags+=("--dry-run") ;;
    esac
fi

# Run the installer with selected flags
echo "Running installer with flags: ${installer_flags[*]}"
bash "$DOTFILES_DIR/install/install.sh" "${installer_flags[@]}"