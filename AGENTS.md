# AGENTS.md — NixOS Configuration Guide for AI Agents

> Host: sgnixos | NixOS 26.05 (Yarara) | x86_64-linux | HP ZHAN 66 Pro A 14 G3

## Project Overview

This is a NixOS system configuration based on **Nix Flakes**, employing a modular design and integrating **Home Manager** to manage user configurations.

- **System Upgrade Records (2026-07-14)**:
  - Introduced and packaged the `oh-my-pi` (omp) AI coding agent. Since Bun's single-file executables use a trailer mechanism to append JS scripts, traditional `patchelf` breaks segment offsets, degrading it to a standard Bun CLI. Therefore, a dynamic loader wrapper solution was implemented.
  - Successfully integrated the `omp` package into the local personal NUR repository `sgnur-packages`, removed the local package definition in `/etc/nixos`, and declaratively integrated it into the Home Manager package list via the `myRepo` dynamic overlay.
- **System Upgrade Records (2026-07-13)**:
  - Decoupled software packages by migrating GUI applications to Home Manager.
  - Introduced the `home/lib.nix` helper library for unified dotfile management.
  - Fixed XDG subdirectory path mapping logic.

## Directory Structure

```
/etc/nixos/
├── flake.nix                    # Flake entry point
├── configuration.nix            # Main configuration (imports only)
├── modules/                     # NixOS system modules
│   ├── desktop/                 # Desktop environment (niri/cosmic/audio/fonts)
│   ├── packages/                # Core system packages
│   ├── services/                # System services (ssh/greetd/xray/univpn/storage)
│   └── system/                  # System base configuration (boot/locale/network/nix/users)
├── home/                        # Home Manager configuration
│   ├── home.nix                 #   HM entry point
│   ├── lib.nix                  #   Shared helper library (e.g., mkDotfileLinks)
│   ├── packages/                #   User-level package management
│   └── programs/                #   Modular program configurations
└── dotfiles/                    # Symlink source configuration files
```

## Common Commands

```bash
# Build and switch system configuration
sudo nixos-rebuild switch --flake /etc/nixos#sgnixos

# Check user service status
systemctl --user status dms.service
```

## Dotfiles Deployment Logic

- All user configurations are stored in the `dotfiles/` directory.
- XDG symlinks are created via the `mkDotfileLinks` helper function defined in `home/lib.nix`.
- Modifying files inside `dotfiles/` does not require a rebuild; applications will pick up changes automatically.
- **Note**: If a conflict occurs during building due to existing `*.backup` files, clean up the conflicting `~/.config/<program>/*.backup` files.

## Important Notes

- `secrets.nix` is not tracked by Git. Run the `rebuild` alias (which includes `--update-input secrets-file`) after modifying secrets.
- `allowUnfree` is enabled globally inside Home Manager; no additional setup is required.
