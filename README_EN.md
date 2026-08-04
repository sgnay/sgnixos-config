# sgnixos — NixOS Flake Configuration

> **主机**: sgnixos · **架构**: x86_64-linux · **硬件**: HP ZHAN 66 Pro A 14 G3 (AMD Ryzen)
>
> **NixOS 26.05 (Yarara)** · **Zen Kernel** · **niri + dms-shell (主桌面)** · **COSMIC (备选)**

---

## 🖥️ Overview

A modular, production-grade NixOS configuration managed via **Nix Flakes**, with **Home Manager** integrated as a NixOS module.

### Recent Optimizations
- **2026-08-03: Podman & Libvirtd/QEMU Stack Enhancement**
  - **Podman Suite**: Enhanced `modules/packages/virtualization.nix` with Podman container runtime, Docker CLI alias (`dockerCompat = true`), `/var/run/docker.sock` socket compatibility (`dockerSocket.enable = true`), and Netavark/Aardvark-dns inter-container DNS resolution.
  - **Libvirtd Virtualization**: Enabled `virtualisation.libvirtd` with QEMU `swtpm` (TPM 2.0 emulation for VMs like Windows 11). Configured and set autostart for the libvirt `default` NAT network.
  - **Tooling & User Groups**: Included `virt-manager`, `virt-viewer`, `spice`, `podman-compose`, `buildah`, and `skopeo` packages, and assigned user permissions to `libvirtd` and `podman` system groups.
- **2026-08-03: NFS Automount Freeze Fix & Declarative Timer Probe**
  - **Root Cause & fstab Generator Fix**: Addressed issue where accessing `/home/data/_mountpoint_nfs` froze operations when NFS server (port 2049) was unreachable despite `noauto` setting. Removed `x-systemd.automount` from `fileSystems` to avoid `systemd-fstab-generator` creating auto-enabled autofs triggers.
  - **Declarative Systemd Automount & Timer**: Explicitly declared `systemd.automounts` with `wantedBy = []` in `modules/services/network-storage.nix` to prevent mask issues and disable boot-time auto-enabling. Added `nfs-automount-watcher.service` (oneshot `nc` port check) and `nfs-automount-watcher.timer` (15s interval) to dynamically start the automount unit when port 2049 is reachable and stop it when unreachable, eliminating memory footprint while preventing filesystem freezes.
- **2026-08-03: Thunar Default Terminal Integration for Ghostty**
  - **Custom Action (uca.xml)**: Configured `dotfiles/Thunar/uca.xml` with `ghostty --working-directory=%f` for the "Open Terminal Here" action.
  - **Declarative Symlinking**: Added `home/programs/thunar.nix` using `mkDotfileLinks` to link `dotfiles/Thunar/uca.xml` to `~/.config/Thunar/uca.xml`, and set `TERMINAL="ghostty"` in `home.sessionVariables`.
- **2026-08-03: Neovim Clipboard Hardening & Keymaps**
  - **LazyVim Clipboard Override Fix**: Resolved LazyVim's `VeryLazy` event resetting `vim.opt.clipboard` back to `unnamedplus`. Added `VimEnter`, `VeryLazy`, and `OptionSet` `autocmd` hooks in `home/programs/neovim.nix` to enforce `vim.opt.clipboard = ""`.
  - **Dedicated System Clipboard Keymaps**: Prevented standard `x/y/d/c` operations from polluting system clipboard history, explicitly mapping `<leader>y` (copy), `<leader>d` (cut), and `<leader>p` (paste) to interact with the system `+` register.
- **2026-08-03: WPS Office HiDPI Scaling & Niri Launcher Fix**
  - **DPI Environment Variable**: Set `QT_FONT_DPI=144` in Niri `dotfiles/niri/environment.kdl` to scale Qt-based WPS Office UI text globally.
  - **Launcher Exec Path Rewrite**: Resolved launcher silent launch failures by wrapping `wpsoffice-cn` with `symlinkJoin` + `makeWrapper` in `home/packages/default.nix` to rewrite `.desktop` `Exec` paths.
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
