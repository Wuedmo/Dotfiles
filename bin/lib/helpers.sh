#!/bin/bash

# Icons
_ICON_STEP="▸"
_ICON_INFO="→"
_ICON_SUCCESS="✓"
_ICON_ERROR="✗"
_ICON_ARROW="›"

_has_gum() {
  command -v gum &>/dev/null
}

# Source shared install helpers when available to expose pkg_install/is_cachyos
if [ -f "$HOME/.local/share/dotfiles/install/lib/helpers.sh" ]; then
  # shellcheck source=/dev/null
  source "$HOME/.local/share/dotfiles/install/lib/helpers.sh"
fi

# Propagate DRY_RUN and FORCE_CACHYOS from environment so bin scripts
# can respect dry-run and CachyOS modes when invoked separately.
DRY_RUN=${DRY_RUN:-false}
FORCE_CACHYOS=${FORCE_CACHYOS:-false}
export DRY_RUN FORCE_CACHYOS

# Parse common CLI flags: --dry-run/-n and --cachyos
# Usage: parse_common_flags "$@"  (function will export DRY_RUN and FORCE_CACHYOS)
parse_common_flags() {
  local argv=()
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -n|--dry-run)
        DRY_RUN=true; shift ;;
      --cachyos)
        FORCE_CACHYOS=true; shift ;;
      --)
        shift
        while [[ $# -gt 0 ]]; do argv+=("$1"); shift; done
        break
        ;;
      *) argv+=("$1"); shift ;;
    esac
  done
  export DRY_RUN FORCE_CACHYOS
  # Echo remaining args (space-separated) so callers may reassign if desired
  if [ ${#argv[@]} -gt 0 ]; then
    printf '%s\n' "${argv[@]}"
  fi
}

_ensure_gum() {
  if ! _has_gum; then
    echo "Error: gum is required but not installed."
    echo "Install it with: sudo pacman -S gum"
    exit 1
  fi
}

_ensure_gum

# Visible marker for dry-run mode so test harnesses can detect it
if [ "$DRY_RUN" = true ]; then
  echo "DRY-RUN MODE: scripts will not apply changes"
fi

log_header() {
  local text="$1"

  echo
  gum style \
    --foreground 2 \
    --border double \
    --border-foreground 2 \
    --padding "0 1" \
    --width 40 \
    --align center \
    "$text"
  echo
}

log_step() {
  local text="$1"

  echo
  gum style \
    --foreground 2 \
    --bold \
    "$_ICON_STEP $text"
}

log_info() {
  local text="$1"

  gum style \
    --foreground 8 \
    "  $_ICON_INFO $text"
}

log_success() {
  local text="$1"

  gum style \
    --foreground 2 \
    "  $_ICON_SUCCESS $text"
}

log_error() {
  local text="$1"

  gum style \
    --foreground 9 \
    --bold \
    "  $_ICON_ERROR $text"
}

log_detail() {
  local text="$1"

  gum style \
    --foreground 8 \
    "    $_ICON_ARROW $text"
}

spinner() {
  local title="$1"
  shift

  gum spin \
    --spinner dot \
    --title "$title" \
    --show-error \
    -- "$@"
}

ask_yes_no() {
  local prompt="$1"

  gum confirm \
    --prompt.foreground=2 \
    --selected.foreground=15 \
    --selected.background=2 \
    "$prompt" && return 0 || return 1
}

log_progress() {
  local text="$1"
  local count="$2"

  gum style \
    --foreground 2 \
    "  [$count] $text"
}

show_done() {
  echo
  gum spin --spinner "dot" --title "Done! Press any key to close..." -- bash -c 'read -n 1 -s'
}
