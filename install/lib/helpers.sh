#!/bin/bash

_GREEN='\033[0;32m'
_BLUE='\033[0;34m'
_YELLOW='\033[1;33m'
_RED='\033[0;31m'
_CYAN='\033[0;36m'
_NC='\033[0m'

_ICON_STEP="▸"
_ICON_INFO="→"
_ICON_SUCCESS="✓"
_ICON_ERROR="✗"
_ICON_ARROW="›"

_has_gum() {
    command -v gum &> /dev/null
}

is_installed() {
    pacman -Q "$1" &>/dev/null
}

ensure_gum() {
    if ! is_installed "gum"; then
        echo "Installing gum for better UI..."
        sudo pacman -S --noconfirm gum
    fi
}

log_header() {
    local text="$1"

    if _has_gum; then
        echo
        gum style \
            --foreground 108 \
            --border double \
            --border-foreground 108 \
            --padding "0 2" \
            --margin "1 0" \
            --width 50 \
            --align center \
            "$text"
        echo
    else
        echo -e "\n${_GREEN}════════════════════════════════════════${_NC}"
        echo -e "${_GREEN}  $text${_NC}"
        echo -e "${_GREEN}════════════════════════════════════════${_NC}\n"
    fi
}

log_step() {
    local text="$1"

    if _has_gum; then
        echo
        gum style \
            --foreground 108 \
            --bold \
            "$_ICON_STEP $text"
    else
        echo -e "\n${_GREEN}$_ICON_STEP${_NC} $text"
    fi
}

log_info() {
    local text="$1"

    if _has_gum; then
        gum style \
            --foreground 246 \
            "  $_ICON_INFO $text"
    else
        echo -e "  ${_YELLOW}$_ICON_INFO${_NC} $text"
    fi
}

log_success() {
    local text="$1"

    if _has_gum; then
        gum style \
            --foreground 108 \
            "  $_ICON_SUCCESS $text"
    else
        echo -e "  ${_GREEN}$_ICON_SUCCESS${_NC} $text"
    fi
}

log_error() {
    local text="$1"

    if _has_gum; then
        gum style \
            --foreground 196 \
            --bold \
            "  $_ICON_ERROR $text"
    else
        echo -e "  ${_RED}$_ICON_ERROR${_NC} $text"
    fi
}

log_detail() {
    local text="$1"

    if _has_gum; then
        gum style \
            --foreground 241 \
            "    $_ICON_ARROW $text"
    else
        echo -e "    ${_CYAN}$_ICON_ARROW${_NC} $text"
    fi
}

spinner() {
    local title="$1"
    shift

    if _has_gum; then
        gum spin \
            --spinner dot \
            --title "$title" \
            --show-error \
            -- "$@"
    else
        echo -e "${_CYAN}⟳${_NC} $title"
        "$@"
    fi
}

ask_yes_no() {
    local prompt="$1"

    if _has_gum; then
        gum confirm "$prompt" && return 0 || return 1
    else
        while true; do
            read -p "$prompt [y/n]: " yn
            case $yn in
                [Yy]* ) return 0;;
                [Nn]* ) return 1;;
                * ) echo "Please answer yes or no.";;
            esac
        done
    fi
}

log_progress() {
    local text="$1"
    local count="$2"

    if _has_gum; then
        gum style \
            --foreground 108 \
            "  [$count] $text"
    else
        echo -e "  ${_CYAN}[$count]${_NC} $text"
    fi
}

detect_hardware_type() {
    if ls /sys/class/power_supply/BAT* >/dev/null 2>&1 || [ -d /sys/class/power_supply/battery ]; then
        echo "laptop"
    else
        echo "desktop"
    fi
}

has_nvidia_gpu() {
    lspci | grep -i nvidia &>/dev/null
}

remove_path() {
    local target="$1"

    if [ -L "$target" ] && [ ! -e "$target" ]; then
        rm -f "$target"
    elif [ -e "$target" ]; then
        rm -rf "$target"
    fi
}

# Distro detection and safe execution helpers
is_cachyos() {
    if [ "${FORCE_CACHYOS:-false}" = "true" ]; then
        return 0
    fi
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

# Respect externally provided DRY_RUN flag (exported by test harness or caller)
DRY_RUN=${DRY_RUN:-false}

run_cmd() {
    if [ "$DRY_RUN" = true ]; then
        echo "DRY-RUN: $*"
    else
        eval "$@"
    fi
}

# Package installation helper: prefer official repos on CachyOS, fall back to AUR when allowed
pkg_install() {
    local pkg="$1"
    local use_aur_if_missing="${2:-true}"

    # Try pacman first (official repos)
    if command -v pacman >/dev/null 2>&1; then
        if $DRY_RUN; then
            echo "DRY-RUN: sudo pacman -S --noconfirm --needed $pkg"
            return 0
        fi
        if sudo pacman -S --noconfirm --needed "$pkg" >/dev/null 2>&1; then
            return 0
        fi
    fi

    # If CachyOS prefer repos only (do not fallback to AUR)
    if is_cachyos; then
        return 1
    fi

    # Fallback to paru/yay if allowed
    if [ "$use_aur_if_missing" = true ]; then
        if command -v paru >/dev/null 2>&1; then
            if $DRY_RUN; then
                echo "DRY-RUN: paru -S --noconfirm --needed $pkg"
                return 0
            fi
            paru -S --noconfirm --needed "$pkg" >/dev/null 2>&1 && return 0 || return 1
        elif command -v yay >/dev/null 2>&1; then
            if $DRY_RUN; then
                echo "DRY-RUN: yay -S --noconfirm --needed $pkg"
                return 0
            fi
            yay -S --noconfirm --needed "$pkg" >/dev/null 2>&1 && return 0 || return 1
        fi
    fi

    return 1
}

# Package removal helper: prefer pacman on CachyOS, fallback to AUR helper if present
pkg_remove() {
    local pkg="$1"
    if is_cachyos; then
        run_cmd "sudo pacman -Rns --noconfirm $pkg"
        return
    fi

    if command -v paru >/dev/null 2>&1; then
        run_cmd "paru -Rns --noconfirm $pkg"
    elif command -v yay >/dev/null 2>&1; then
        run_cmd "yay -Rns --noconfirm $pkg"
    else
        run_cmd "sudo pacman -Rns --noconfirm $pkg"
    fi
}

# Kernel detection helpers
get_running_kernel_base() {
    uname -r 2>/dev/null | sed 's/-.*//' || true
}

get_installed_kernel_packages() {
    pacman -Qq "linux*" 2>/dev/null || true
}

# Returns 0 if a reboot is likely needed because installed kernel packages
# do not match the running kernel version. Returns 1 if running kernel
# matches at least one installed kernel package.
kernel_needs_reboot() {
    local running base pkg pkg_ver pkg_base
    running=$(get_running_kernel_base)
    if [ -z "$running" ]; then
        return 1
    fi

    for pkg in $(get_installed_kernel_packages); do
        pkg_ver=$(pacman -Q "$pkg" 2>/dev/null | awk '{print $2}') || continue
        pkg_base=$(echo "$pkg_ver" | sed -E 's/^([0-9]+(\.[0-9]+)*).*/\1/')
        if [ "$pkg_base" = "$running" ]; then
            return 1
        fi
    done

    # No installed kernel matched the running kernel base version
    return 0
}
