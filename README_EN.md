# sgnixos — NixOS Flake Configuration

> **主机**: sgnixos · **架构**: x86_64-linux · **硬件**: HP ZHAN 66 Pro A 14 G3 (AMD Ryzen)
>
> **NixOS 26.05 (Yarara)** · **Zen Kernel** · **niri + dms-shell (主桌面)** · **COSMIC (备选)**

---

## 🖥️ Overview

A modular, production-grade NixOS configuration managed via **Nix Flakes**, with **Home Manager** integrated as a NixOS module.

### Recent Optimizations
- **2026-07-23: Standalone FHS Sandbox Environment**
  - **FHS Environment (fhs.nix)**: Introduced `/etc/nixos/fhs.nix` based on `buildFHSEnv`. It bundles standard C/C++ runtimes, X11/OpenGL graphics libraries, and development utilities, allowing unpatched Linux binaries and SDKs to be executed via `nix-shell /etc/nixos/fhs.nix`.
- **2026-07-14: SOPS-Nix Secrets Refactoring**
  - **Deprecated Plaintext secrets.nix**: Completely removed the untracked `/etc/nixos/secrets.nix` file to prevent accidental deletion and plain-text exposure.
  - **SOPS-Nix Integration**: Introduced `sops-nix` for secrets management. Converted the host's SSH host key (`/etc/ssh/ssh_host_ed25519_key`) and the user's personal key (`~/.ssh/id_ed25519`) into `age` identities, allowing transparent boot decryption and secure local editing.
  - **Runtime Config Rendering**: Encrypted proxy credentials (Xray VLESS outbounds) inside `secrets.yaml`. They are dynamically decrypted and rendered into `/run/secrets/rendered/xray-away.json` (RAMFS) during the system activation phase. The Xray systemd service references this path directly, successfully preventing sensitive tokens/UUIDs from leaking into the world-readable `/nix/store`.
  - **Decoupled Public Parameters**: Moved public settings (`username`, `email`, public SSH keys) to `common.nix` for clean version control.
- **2026-07-14: OMP AI Coding Agent Integration**
  - **Dynamic Linker Wrapping**: Packaged the `oh-my-pi` (omp) AI coding agent. Bun's standalone binary embeds its JS payload as a trailing archive, so traditional `patchelf` corrupts the offset. Resolved this by wrapping the unmodified binary with the glibc dynamic interpreter (`ld-linux-x86-64.so.2`).
  - **Declarative NUR Overlay**: Promoted the `omp` package to the personal `sgnur-packages` repository, updating the Flake inputs overlay and Home Manager packages accordingly.
- **2026-07-13: Architecture Decoupling & Dotfiles**
  - **Architecture Decoupling**: Moved GUI applications from `environment.systemPackages` to Home Manager for cleaner system profiles.
  - **Dotfile Management**: Refactored symlinking into a unified `home/lib.nix` helper (`mkDotfileLinks`) for maintainable and concise XDG configuration.
  - **Build Robustness**: Implemented `lib.mkForce` and cleanup logic to resolve Home Manager activation conflicts.

---

## 📁 Directory Structure (Core)

- `flake.nix`: Entry point (imports `sops-nix` module).
- `configuration.nix`: Minimal system imports.
- `common.nix`: Public system & user variables.
- `fhs.nix`: Standalone FHS sandbox environment (buildFHSEnv).
- `.sops.yaml`: SOPS key configuration and recipient rules.
- `secrets.yaml`: SOPS encrypted configuration database.
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

### Secrets Maintenance

```bash
# Edit secrets.yaml using your personal SSH key (automatically decrypts/re-encrypts)
nix-shell -p sops --run "sops secrets.yaml"
```

### Secrets Disaster Recovery
If you reinstall the OS or move to a new machine, your host SSH key will change. As long as you have backed up your personal user SSH key (`~/.ssh/id_ed25519`), you can easily recover and update the keys. Detailed step-by-step instructions are documented in the **Secrets Disaster Recovery** section of [AGENTS.md](file:///etc/nixos/AGENTS.md).

### Hot-Reloading Dotfiles
Dotfiles in `dotfiles/` are symlinked using `mkOutOfStoreSymlink`. Edits to these files apply immediately (or after app restart/reload) without needing a system rebuild.
