# sgnixos — NixOS Flake Configuration

> **主机**: sgnixos · **架构**: x86_64-linux · **硬件**: HP ZHAN 66 Pro A 14 G3 (AMD Ryzen)
>
> **NixOS 26.05 (Yarara)** · **Zen Kernel** · **niri + dms-shell (主桌面)** · **COSMIC (备选)**

---

## 🖥️ Overview

A modular, production-grade NixOS configuration managed via **Nix Flakes**, with **Home Manager** integrated as a NixOS module. The system is designed for daily driving on a laptop, featuring:

- 🎨 **Sci-Fi Glassmorphism login** — ReGreet with Orbitron fonts, neon glow, and cyberpunk aesthetics
- 🪟 **Dual desktop environments** — [niri](https://github.com/YaLTeR/niri) (scrollable-tiling Wayland) + [DankMaterialShell](https://gitlab.com/sgnay/dms-shell) (primary), [COSMIC](https://system76.com/cosmic) (fallback)
- 🔒 **Smart proxy** — Xray VLESS+REALITY (away) / local HTTP (home) with GeoIP CN-direct routing
- 🇨🇳 **Full Chinese support** — fcitx5 + Rime-ice (雾凇拼音), Windows/macOS font aliases for Electron apps
- 🎮 **Virtualization ready** — Podman, libvirt + virt-manager
- 🔐 **Security first** — SSH key-only auth, sudo with NOPASSWD for rebuilds
- ☁️ **VPN** — UniVPN (EasyConnect-compatible) commercial VPN client, packaged from `.run` installer
- 📦 **Network storage** — NFS auto-mount, Samba server, Syncthing, KDE Connect

---

## ✨ Highlights

| Feature | Details |
|---------|---------|
| **Login Screen** | Greetd + ReGreet with custom sci-fi glassmorphism CSS — glowing panels, neon clock, particle effects, auto-blanking after 3 min idle |
| **Primary Desktop** | niri (scrollable-tiling Wayland compositor) + dms-shell (GTK/QML panel with system tray) |
| **Fallback Desktop** | COSMIC — System76's Rust-native DE, selectable from ReGreet session list |
| **Input Method** | fcitx5 + Rime-ice (雾凇拼音) with StatusNotifier tray icon in dms-shell |
| **Font Aliasing** | Windows/macOS → WenQuanYi Micro Hei for Chinese Electron apps (QQ Music, WeChat, etc.) |
| **Proxy System** | Two-mode Xray: `proxy-home` (local gateway) / `proxy-away` (VLESS+REALITY), GeoIP CN-direct |
| **Terminal** | WezTerm (Lua config) + Ghostty (custom GLSL shader) |
| **Shell** | Fish + Starship (gruvbox) with `bat`/`dust`/`fd`/`eza`/`sd` aliases |
| **Kernel** | Zen (default) with stable kernel as `specialisation` option in systemd-boot |
| **Boot** | systemd-boot, Plymouth splash (breeze theme), `quiet` boot, 5-gen limit |
| **Packaging** | UniVPN client extracted from `.run` self-extracting archive — reference for commercial software on NixOS |

---

## 📁 Directory Structure

```
/etc/nixos/
├── flake.nix                     # Flake entry: inputs + outputs (system config + home-manager)
├── flake.lock                    # Pinned dependency versions
├── configuration.nix             # Minimal main config — imports only
├── hardware-configuration.nix    # Auto-generated hardware config (do not edit)
├── common.nix                    # Shared variables (DNS, proxy host/port)
├── secrets.nix                   # Sensitive data (username, SSH keys) — NOT in git
├── secrets.nix.example           # Template for secrets.nix
├── AGENTS.md                     # AI assistant guide (internal)
├── modules/                      # NixOS system modules
│   ├── desktop/                  # Desktop environment
│   │   ├── niri.nix              #   niri compositor + dms-shell (system-level)
│   │   ├── cosmic.nix            #   COSMIC DE (fallback, no cosmic-greeter)
│   │   ├── fonts.nix             #   Fonts + fontconfig aliases (Windows/macOS → FOSS)
│   │   └── audio.nix             #   PipeWire audio
│   ├── packages/                 # Software packages (grouped by category)
│   │   ├── browsers.nix          #   Firefox, Google Chrome
│   │   ├── terminals.nix         #   WezTerm, Ghostty
│   │   ├── office.nix            #   Joplin Desktop, WPS Office
│   │   ├── file-manager.nix      #   Thunar + plugins, MegaSync
│   │   ├── input.nix             #   fcitx5 + Rime-ice + themes (Nord, Fluent, Catppuccin)
│   │   ├── communication.nix     #   WeChat, QQ, Tencent Meeting, Telegram, LocalSend
│   │   ├── multimedia.nix        #   VLC, mpv, QQ Music, OBS, Sunshine, Flameshot
│   │   ├── editors.nix           #   VSCode FHS, Neovim
│   │   ├── virtualization.nix    #   Podman (Docker compat), libvirt + virt-manager
│   │   └── thunar-themes.nix     #   Thumbnailers for Thunar
│   ├── services/                 # System services
│   │   ├── ssh.nix               #   OpenSSH key-only auth
│   │   ├── greetd.nix            #   Greetd + ReGreet graphical login (sci-fi CSS)
│   │   ├── xray.nix              #   Xray VLESS+REALITY proxy (dual-mode)
│   │   └── network-storage.nix   #   KDE Connect, NFS, Samba, Syncthing
│   └── system/                   # System base
│       ├── base.nix              #   logind, base packages, EDITOR, state version
│       ├── boot.nix              #   systemd-boot (5-gen limit), Zen kernel, Plymouth
│       ├── locale.nix            #   Timezone Shanghai, en_US + zh_CN
│       ├── network.nix           #   NetworkManager, proxy, firewall
│       ├── nix-config.nix        #   Flakes, substituters (USTC→SJTU), allowUnfree, GC
│       └── users.nix             #   Users + sudo rules
├── home/                         # Home Manager configuration
│   ├── home.nix                  #   HM entry: imports, GTK theme, session variables
│   └── programs/
│       ├── git.nix               #   Git config (user, aliases)
│       ├── shell.nix             #   Fish + Starship + CLI tools (bat/dust/fd/eza/sd/yazi)
│       ├── niri.nix              #   niri KDL deployment + dms-shell override + ecosystem
│       ├── wezterm.nix           #   WezTerm Lua module deployment
│       ├── ghostty.nix           #   Ghostty config + Cascadia Code + shader
│       └── rime.nix              #   Rime-ice (雾凇拼音) install & config
├── dotfiles/                     # User config file sources (hot-reloadable)
│   ├── niri/                     #   niri KDL config + dms/ subdirectory
│   ├── wezterm/                  #   WezTerm modular Lua config
│   ├── ghostty/                  #   Ghostty config + GLSL shaders
│   ├── fish/                     #   Fish shell config.fish + custom functions
│   └── starship/                 #   Starship gruvbox prompt config
```

---

## 🚀 Quick Start

### Prerequisites

1. **Clone or copy this repository** to `/etc/nixos/` on a NixOS machine with Flakes enabled.
2. **Create `secrets.nix`** from the template:
   ```bash
   cp /etc/nixos/secrets.nix.example /etc/nixos/secrets.nix
   vi /etc/nixos/secrets.nix   # Fill in your username, SSH keys, etc.
   ```

### Build & Apply

```bash
# Test build (no reboot, immediate apply)
sudo nixos-rebuild test --flake /etc/nixos#sgnixos

# Switch (set as default boot entry + apply now)
sudo nixos-rebuild switch --flake /etc/nixos#sgnixos

# Switch with secrets.nix update (一步到位)
sudo nixos-rebuild switch --flake /etc/nixos#sgnixos --update-input secrets-file
# Fish alias:
rebuild

# Boot only (next reboot only)
sudo nixos-rebuild boot --flake /etc/nixos#sgnixos

# Dry run (validate only)
nixos-rebuild dry-build --flake /etc/nixos#sgnixos
```

### Update Flake Lock

```bash
# 更新所有 inputs（包括 secrets-file 的 narHash）
nix flake update --flake /etc/nixos

# 仅更新 secrets-file（更快，不查 GitHub API）
nix flake update --flake /etc/nixos --update-input secrets-file
```

### Apply Home Manager Only (standalone mode)

```bash
home-manager switch --flake /etc/nixos#sgnay
```

---

## 🎮 Desktop Session Selection

On the ReGreet login screen, you can choose between:

| Session | Description |
|---------|-------------|
| **niri** | Primary — scrollable-tiling Wayland compositor with dms-shell panel |
| **COSMIC** | Fallback — System76 Rust-native desktop environment |

Both are auto-detected from their `.desktop` files.

---

## 🌐 Proxy System

### Quick Switch

| Command | Mode | Description |
|---------|------|-------------|
| `proxy-away` | VLESS+REALITY | External proxy (for travel/outdoor use) |
| `proxy-home` | Local HTTP (172.20.26.100:1080) | Home/office LAN proxy |
| `proxy-off` | None | Clear all proxy variables |

All proxy env vars point to `127.0.0.1:1080` (HTTP) / `1081` (SOCKS5). Xray handles routing and GeoIP-based CN-direct logic.

### GUI Alternative

`clash-verge-rev` is installed as a GUI proxy management client.

### Troubleshooting — Proxy Bootstrap Loop

If the proxy service isn't running during a rebuild and `HTTP_PROXY` is set, `nix-daemon` will fail to reach substituters:

```bash
# 1. Clear nix-daemon proxy temporarily
sudo systemctl set-environment HTTP_PROXY= HTTPS_PROXY= http_proxy= https_proxy= all_proxy= ALL_PROXY=
sudo systemctl restart nix-daemon

# 2. Rebuild (proxy service will start as part of the config)
sudo nixos-rebuild test --flake /etc/nixos#sgnixos

# 3. Proxy auto-restores after rebuild
```

---

## ⌨️ Common Commands

```bash
# DMS Service Status (bound to niri session)
systemctl --user status dms.service
journalctl --user -u dms.service -f

# Garbage Collection + Clean Boot Entries
sudo nix-collect-garbage -d
sudo nixos-rebuild boot --flake /etc/nixos#sgnixos

# UniVPN Management
univpn              # Start VPN client (auto-escalate)
univpn-stop         # Stop all UniVPN processes
univpn-restart      # Restart VPN client

# Samba Password (first time use)
sudo smbpasswd -a <username>

# Boot into Stable Kernel
# Reboot → systemd-boot menu → select "sgnixos (stable-kernel)"
```

---

## 🔧 Configuration Guide

### Hot-Reloadable Dotfiles

All user configuration files in `dotfiles/` are symlinked via `mkOutOfStoreSymlink`. This means:
- Edit the source file in `dotfiles/`
- The change takes effect **immediately** — no `nixos-rebuild` needed
- Exception: adding/removing packages or changing system modules still requires rebuild

**Hot-reloadable files:**
- `dotfiles/niri/*.kdl` — niri compositor config (reload with `niri msg action reload-config`)
- `dotfiles/wezterm/*.lua` — WezTerm config (live-reloads on save)
- `dotfiles/ghostty/*` — Ghostty config (restart terminal to apply)
- `dotfiles/fish/config.fish` — Fish shell config (re-sourced on new shell)
- `dotfiles/starship/starship.toml` — Starship prompt (instant)

### Adding Packages

1. Identify the correct category file in `modules/packages/`
2. Add the package to `environment.systemPackages`
3. Rebuild: `sudo nixos-rebuild test --flake /etc/nixos#sgnixos`

For user-level packages, add to the appropriate `home/programs/*.nix` and rebuild.

### Adding a New Module

1. Create `modules/<category>/<name>.nix` following the `{ config, pkgs, ... }` pattern
2. Add to `imports` in `configuration.nix`
3. Rebuild

### Customizing the Login Screen

The ReGreet CSS is defined in `modules/services/greetd.nix` as the `sciFiCss` variable. Edit it and rebuild to apply. Greeting message can be changed via `settings.appearance.greeting_msg`.

---

## 🧩 Key Components in Detail

### niri + dms-shell

The dms-shell systemd user service is overridden to bind to `niri.service` (not `graphical-session.target`), so DMS only launches in niri sessions — COSMIC sessions are unaffected. Full PATH containing `quickshell`, `dms-shell`, and user profile is set via `Service.Environment`.

### ReGreet Login Screen

- **Engine**: Cage (minimal Wayland compositor) running ReGreet
- **Theme**: Catppuccin-Mocha base + fully custom glassmorphism CSS
- **Fonts**: Orbitron (headings, sci-fi) + JetBrains Mono (clock, monospace)
- **Background**: Tarantula Nebula (NASA PIA23646) from COSMIC wallpapers
- **Features**: Clock with neon glow, session dropdown, power buttons, error info bar
- **Auto-blanking**: Display turns off after 3 min of inactivity (`swayidle` + `wlr-randr`), wakes on input

### Font Aliasing (Chinese Electron Apps)

Chinese Electron apps (QQ Music, WeChat, WPS Office) request Windows/macOS font names. The system maps them to free alternatives via fontconfig:
- `Microsoft YaHei / PingFang SC → WenQuanYi Micro Hei`
- `SimSun → Noto Serif CJK SC`
- `Segoe UI / Tahoma → Noto Sans`
- `Wingdings / Symbol → DejaVu Sans / Symbola`

### Xray Proxy Architecture

```
Internet ←→ VLESS+REALITY (away)
                     ↓
              Xray Core ←→ GeoIP:cn → direct (bypass)
                     ↓
           HTTP 127.0.0.1:1080 (system proxy)
           SOCKS5 127.0.0.1:1081
```

Two systemd services: `xray` (away mode, VLESS outbound) and `xray-home` (local proxy outbound).

### UniVPN Commercial Client

> Module source: [sgnur-packages](https://github.com/sgnay/sgnur-packages) external flake repository
> Import: `inputs.myRepo.nixosModules.univpn` in `configuration.nix`

UniVPN packaging and configuration has been extracted to the [sgnur-packages](https://github.com/sgnay/sgnur-packages) repository. The installer zip is managed by that repo's flake inputs.

**Import approach:**
```nix
# flake.nix
inputs.myRepo = {
  url = "github:sgnay/sgnur-packages";  # or path:... for local dev
  inputs.nixpkgs.follows = "nixpkgs";
};

# configuration.nix
imports = [ inputs.myRepo.nixosModules.univpn ];
services.univpn.enable = true;

# overlays
nixpkgs.overlays = [
  (final: prev: { univpn = inputs.myRepo.packages."${prev.system}".univpn; })
];
```

**Management commands (provided by the external module):**
- `univpn` — Start VPN client (auto-escalate)
- `univpn-stop` — Stop all UniVPN processes
- `univpn-restart` — Restart VPN client

Full packaging docs (self-extracting archive, setuid, Qt5 replacement, etc.) in the [sgnur-packages repo](https://github.com/sgnay/sgnur-packages).

---

## 🐛 Known Issues & Fixes

### Fish + Home Manager Config Conflict
`programs.fish.enable` vs custom `config.fish` → use `lib.mkForce` to override HM's generated file. `home-manager.backupFileExtension = "backup"` handles file conflicts.

### Mise Fish Integration
`eval "$(mise activate fish)"` must specify `fish` shell, otherwise mise outputs bash syntax.

### Fcitx5 Tray Icon Not Showing
Install `adwaita-icon-theme` (provides `input-keyboard-symbolic`), enable `notificationitem` addon, set `PreferTextIcon=True` in classicui.conf.

### WezTerm FiraCode Font Issue
WezTerm can't match "Fira Code" as a named instance of the variable font. Fontconfig alias `Fira Code → FiraCode Nerd Font` (which has static weights) fixes this.

### 32-bit Audio
Disabled by default (`alsa.support32Bit = false`). Re-enable if Steam/Wine 32-bit audio is needed — triggers i686 openblas compile, no binary cache.

### Proxy Bootstrap Loop
See [Proxy Troubleshooting](#troubleshooting--proxy-bootstrap-loop) above.

### Qt Theme
Managed via `qt6ct` with `QT_QPA_PLATFORMTHEME=qt6ct`. Set `QT_SCALE_FACTOR=1.0`.

---

## 📜 Credits

- **NixOS** — [nixos.org](https://nixos.org)
- **niri** — [github.com/YaLTeR/niri](https://github.com/YaLTeR/niri)
- **dms-shell** — [gitlab.com/sgnay/dms-shell](https://gitlab.com/sgnay/dms-shell)
- **ReGreet** — [github.com/rharish101/ReGreet](https://github.com/rharish101/ReGreet)
- **COSMIC** — [system76.com/cosmic](https://system76.com/cosmic)
- **Home Manager** — [nix-community/home-manager](https://github.com/nix-community/home-manager)
- **Rime-ice** — [rime-ice](https://github.com/iDvel/rime-ice)
- **Catppuccin** — [catppuccin.com](https://catppuccin.com)

---

<p align="center">
  <sub>Built with 🦀 and ❄️ on NixOS</sub>
</p>