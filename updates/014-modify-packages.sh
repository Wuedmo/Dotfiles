#!/bin/bash

# Prefer using pkg_install helper when available
if [ -f "$HOME/.local/share/dotfiles/install/lib/helpers.sh" ]; then
  # shellcheck source=/dev/null
  source "$HOME/.local/share/dotfiles/install/lib/helpers.sh"
fi

if ! pacman -Qq matugen &>/dev/null; then
  pkg_install matugen || true
fi

if ! pacman -Qq gjs &>/dev/null; then
  pkg_install gjs || true
fi

if ! pacman -Qq tinte &>/dev/null; then
  pkg_install tinte || true
fi

if ! pacman -Qq gpu-screen-recorder &>/dev/null; then
  pkg_install gpu-screen-recorder || true
fi

if pacman -Qq kooha &>/dev/null; then
  if command -v pkg_remove >/dev/null 2>&1; then
    pkg_remove kooha || true
  else
    # Prefer pkg_remove helper when available, otherwise use pacman
    if command -v pkg_remove >/dev/null 2>&1; then
      pkg_remove kooha || true
    else
      run_cmd "sudo pacman -Rns kooha --noconfirm" || true
    fi
  fi
fi

if ! pacman -Qq usbutils &>/dev/null; then
  pkg_install usbutils || true
fi
