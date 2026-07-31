# AGENTS.md — NixOS Configuration Guide for AI Agents

> Host: sgnixos | NixOS 26.05 (Yarara) | x86_64-linux | HP ZHAN 66 Pro A 14 G3

## Project Overview

This is a NixOS system configuration based on **Nix Flakes**, employing a modular design and integrating **Home Manager** to manage user configurations.

- **System Upgrade Records (2026-07-31)**:
  - **OxideTerm Package & Niri Launcher Fix**: Packaged `oxideterm` (AI-native workspace for SSH/remote machines in Rust/GPUI) into NixOS/Home Manager using local derivation with `makeWrapper`. Resolved Niri/Wayland GUI launcher silent crash issues caused by `nix-shell` non-interactive invocation and missing `XDG_DATA_DIRS` / `LD_LIBRARY_PATH`.

- **System Upgrade Records (2026-07-23)**:
  - **FHS Environment Configuration**: Added `fhs.nix` based on `buildFHSEnv` to provide a standard Linux FHS sandbox environment for executing unpatched third-party binaries and SDKs without requiring `patchelf`.

- **System Upgrade Records (2026-07-14)**:
  - **SOPS-Nix Secrets Overhaul**: Permanently deleted the plain-text local `secrets.nix` file. Configured `sops-nix` utilizing the host's SSH host key (`/etc/ssh/ssh_host_ed25519_key`) and the user's personal key (`~/.ssh/id_ed25519`) as age decryption identities.
  - **Runtime Config Rendering**: Sensitive credentials (such as VLESS Outbounds) are encrypted in `secrets.yaml`. At boot/activation time, `sops-nix` decrypts them and dynamically renders `xray-away.json` into `/run/secrets/rendered/xray-away.json` (RAMFS). This protects credentials from being stored in the world-readable `/nix/store`.
  - **Variable Decoupling**: Moved non-sensitive values (`username`, `email`, public SSH keys) into a new public `common.nix` file which is tracked in git.
  - **Oh My Pi (omp) integration**: Packaged the `oh-my-pi` AI coding agent using a dynamic loader wrapper solution since traditional `patchelf` breaks Bun JS payloads. Published it to `sgnur-packages` and imported it declaratively via overlays.

- **System Upgrade Records (2026-07-13)**:
  - Decoupled software packages by migrating GUI applications to Home Manager.
  - Introduced the `home/lib.nix` helper library for unified dotfile management.
  - Fixed XDG subdirectory path mapping logic.

## Directory Structure

```
/etc/nixos/
├── flake.nix                    # Flake entry point
├── configuration.nix            # Main configuration (imports only)
├── common.nix                   # Public system & user variables
├── fhs.nix                      # Standalone FHS sandbox environment (buildFHSEnv)
├── .sops.yaml                   # SOPS recipient key configs
├── secrets.yaml                 # SOPS encrypted secrets (xray outbounds, etc.)
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

# Launch FHS environment for unpatched binaries
nix-shell /etc/nixos/fhs.nix

# Edit encrypted secrets file
nix-shell -p sops --run "sops secrets.yaml"

# Check user service status
systemctl --user status dms.service
```

## Dotfiles Deployment Logic

- All user configurations are stored in the `dotfiles/` directory.
- XDG symlinks are created via the `mkDotfileLinks` helper function defined in `home/lib.nix`.
- Modifying files inside `dotfiles/` does not require a rebuild; applications will pick up changes automatically.
- **Note**: If a conflict occurs during building due to existing `*.backup` files, clean up the conflicting `~/.config/<program>/*.backup` files.

## Secrets Disaster Recovery (Key Rotation / Re-keying)

If you reinstall NixOS or move to a new machine, the system host key (`/etc/ssh/ssh_host_ed25519_key`) will change. As long as you have backed up your personal user key (`~/.ssh/id_ed25519`), you can easily recover and re-encrypt the secrets:

1. Restore your personal key to `/home/sgnay/.ssh/id_ed25519`.
2. Generate the new `age` public key from the new machine's SSH host key:
   ```bash
   nix-shell -p ssh-to-age --run "ssh-to-age < /etc/ssh/ssh_host_ed25519_key.pub"
   # Output: age1...
   ```
3. Update the `&host` public key entry in `/etc/nixos/.sops.yaml` with the new age key.
4. Run the SOPS update keys command to decrypt the file using your personal key and re-encrypt it with the new host key:
   ```bash
   nix-shell -p sops --run "sops updatekeys secrets.yaml"
   ```
5. Apply the configuration:
   ```bash
   sudo nixos-rebuild switch --flake /etc/nixos#sgnixos
   ```

## Important Notes

- **Secrets Management**: Do NOT write plaintext secrets in git. Always edit `secrets.yaml` using the `sops` wrapper. Non-sensitive settings belong in `common.nix`.
- `allowUnfree` is enabled globally inside Home Manager; no additional setup is required.

## GUI Applications & Launcher Packaging Guide (GUI 应用与 Launcher 打包避坑指南)

### 1. 核心问题现象与根因 (Symptom & Root Cause)
- **现象**：GUI 可执行文件在终端直接运行或通过临时包装脚本运行正常，但从 Niri Launcher、fuzzel、rofi 或桌面应用菜单中点击图标**毫无反应**或**静默退出**。
- **根因分析**：
  1. **禁止在 Launcher 入口使用 `nix-shell`**：桌面 Launcher（如 Wayland 下的 fuzzel/rofi/niri launcher）会在非交互式（non-interactive）、无终端 TTY 且环境变量清理过的子进程中拉起 `.desktop` 中的 `Exec` 命令。在此时调用 `nix-shell` 会因缺少 TTY / 交互式 PATH 导致阻塞或报错退出。
  2. **缺失关键环境前缀 (`XDG_DATA_DIRS`, `GDK_BACKEND`, `LD_LIBRARY_PATH`)**：GUI 应用（如基于 GPUI / GTK / Tauri / Qt 的应用）依赖系统的 Fontconfig、GSettings Schemas、Vulkan 以及 Wayland 动态库。缺少 `XDG_DATA_DIRS` 会导致应用无法加载图标/主题/Schema 在后台崩溃。
  3. **未通过 Home Manager 进行 XDG Symlink 自动注册**：简单手写 `~/.local/share/applications` 无法得到自动规范管理，且容易写错相对命令路径。

### 2. 标准解决方案与规范流程 (Best Practice Workflow)
1. **使用 Nix 原生 Derivation + `makeWrapper` 构建标准包**：
   - 在 `/etc/nixos/pkgs/app.nix` 或 NUR 仓库中定义 `stdenv.mkDerivation` 或 `buildRustPackage`。
   - 使用 `makeWrapper` 将动态库路径写入 `LD_LIBRARY_PATH`：
     ```nix
     makeWrapper $out/bin/app-raw $out/bin/app \
       --prefix LD_LIBRARY_PATH : "${libPath}" \
       --prefix XDG_DATA_DIRS : "${pkgs.fontconfig}/share:${pkgs.gtk3}/share/gsettings-schemas/gtk+3-${pkgs.gtk3.version}"
     ```
2. **在 Derivation 中自动生成与安装 `.desktop` 文件**：
   - 将图标复制到 `$out/share/icons/hicolor/.../apps/app.png`。
   - 生成 `$out/share/applications/app.desktop`，`Exec` 指向 `$out/bin/app %U`。
3. **在 Home Manager 中声明式引入 (`home/packages/default.nix`)**：
   - 引入包 `(callPackage ../../pkgs/app.nix {})`。
   - Home Manager 会自动将 `$out/bin/app` Symlink 至 `~/.nix-profile/bin/`，并将 `$out/share/applications/app.desktop` Symlink 至 `~/.nix-profile/share/applications/`。
   - Niri Launcher 等桌面环境通过标准 `XDG_DATA_DIRS` 索引 `~/.nix-profile/share`，实现 100% 毫秒级稳定拉起。

