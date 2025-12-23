# Wuedmo's Dotfiles 

- CachyOS/Arch
- Hyperland


Quick info:

- [bin](bin) - all scripts live here, it is added to path in uwsm config
- [install](install/install) - main installation script
- [pkgs.txt](install/pkgs.txt) - packages to be installed
- [setup-applications](install/setup-applications) - hides some annoying applications from launcher
- [setup-by-hardware](install/setup-by-hardware) - sets up monitors, keybindings, hypr enviroments
- [setup-config](install/setup-config) - copies full config into ~/.config
- [setup-lazyvim](install/setup-lazyvim) - lazyvim setup
- [setup-nvidia](install/setup-nvidia) - nvidia specific setup
- [setup-system](install/setup-system) - ufw, pacman.conf, triggers nvidia-setup if on nvidia gpu, git, ly login manager (if exists), enables gcr agent for ssh, disables systemd-networkd-wait-online.service that causes extremly long boot time
- [setup-theme](install/setup-theme) - theming setup and symlinks
- [setup-zsh](install/setup-zsh) - full zsh config with oh-my-zsh, plugins, nice features

## Table of Contents

- [Features](#features)
- [Installation](#installation)
  - [Automatic installer](#automatic-installer)
  - [Manual installation](#manual-installation)

---

## Features

- **Dynamic Theming System** - Switch between static themes or use dynamic theming with Matugen and Pywal
- **Utility Scripts** - Interactive package management; theming; setup of Postgres & database backup and restoration, Docker, Node.js; video download (with yt-dlp), video and image transcoding (using handbrakecli and imagemagick), interactive backups with fzf
- **Modular ZSH Config** - Zsh setup with some nice custom functions like `cp2c` (copy file content to clipboard - c2pc <file_path>) and `c2f` (clipboard content to file c2f <file_path>)
- **Application Configs** - Configs for Ghostty, Waybar, Walker, Elephant, lazyvim and more

---

## Installation

### Automatic installer

```bash
curl -fsSL https://raw.githubusercontent.com/Maciejonos/dotfiles/master/setup.sh | bash
```

### CachyOS / Safe mode

The installer detects CachyOS and prefers official repositories over the AUR. New flags:

- `--cachyos` : run installer in CachyOS-first mode (skips automatic AUR installs unless confirmed).
- `--dry-run` or `-n` : show intended actions without applying changes.

Behavior highlights:

- `/etc/pacman.conf` is no longer overwritten silently — the installer shows a diff and prompts before replacing.
- Critical system edits (PAM, mkinitcpio) are interactive: backups are created, diffs shown, and changes applied only on confirmation.
- Package installs prefer repository packages on CachyOS; AUR helpers (like `paru`) are optional and installed only with confirmation.

Example:

```bash
~/.local/share/dotfiles/install/install.sh --cachyos --dry-run
```

### NVIDIA / initramfs notes

- The installer will detect the initramfs tooling on your system and act accordingly:
  - If `mkinitcpio` is present, the installer will propose safe edits to `/etc/mkinitcpio.conf`, show a unified diff, and ask before applying. It will also offer to regenerate the initramfs (`mkinitcpio -P`). These operations respect `--dry-run`.
  - If `dracut` is present, the installer will not modify dracut configuration automatically. It will provide guidance and suggest running `sudo dracut --force` manually after ensuring required modules are available.

If you prefer to review or apply NVIDIA/initramfs changes manually, run the NVIDIA setup in dry-run mode first to preview changes:

```bash
DRY_RUN=true FORCE_CACHYOS=true ~/.local/share/dotfiles/install/setup-nvidia
```

This prints proposed file operations (they begin with `DRY-RUN:`) without making changes.

### Manual installation

You can manually use the dotfiles without the installer:

1. Clone the repository
2. Copy desired configs from `config/` to `~/.config/` (some configs live in [default](default) directory. Also everything relies on the scripts folder being in path)
3. Copy scripts from `bin/` to your preferred location
4. You can use some install scripts for partial setup if you want