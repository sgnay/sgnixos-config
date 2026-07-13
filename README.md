# sgnixos — NixOS Flake Configuration

> **主机**: sgnixos · **架构**: x86_64-linux · **硬件**: HP ZHAN 66 Pro A 14 G3 (AMD Ryzen)
>
> **NixOS 26.05 (Yarara)** · **Zen Kernel** · **niri + dms-shell (主桌面)** · **COSMIC (备选)**

---

## 🖥️ Overview

A modular, production-grade NixOS configuration managed via **Nix Flakes**, with **Home Manager** integrated as a NixOS module.

### Recent Optimizations (2026-07-13)
- **Architecture Decoupling**: Moved GUI applications from `environment.systemPackages` to Home Manager for cleaner system profiles.
- **Dotfile Management**: Refactored symlinking into a unified `home/lib.nix` helper (`mkDotfileLinks`) for maintainable and concise XDG configuration.
- **Build Robustness**: Implemented `lib.mkForce` and cleanup logic to resolve Home Manager activation conflicts.

---

## 📁 Directory Structure (Core)

- `flake.nix`: Entry point.
- `configuration.nix`: Minimal system imports.
- `modules/system/`: System-level configuration.
- `modules/packages/`: Minimal system-level core tools.
- `home/`: Home Manager configuration.
  - `home.nix`: Entry point.
  - `packages/default.nix`: User-level application management.
  - `programs/`: Individual Home Manager modules (git, niri, wezterm, etc.).
  - `lib.nix`: Reusable helper functions for symlinking.
- `dotfiles/`: Source configuration files (symlinked).

---

## 🚀 Quick Start

### Build & Apply

```bash
# Switch (apply now + set as default boot entry)
sudo nixos-rebuild switch --flake /etc/nixos#sgnixos
```

### Hot-Reloading Dotfiles
Dotfiles in `dotfiles/` are symlinked using `mkOutOfStoreSymlink`. Edits to these files apply immediately (or after app restart/reload) without needing a system rebuild.
