# AGENTS.md — NixOS Configuration Guide for AI Agents

> Host: sgnixos | NixOS 26.05 (Yarara) | x86_64-linux | HP ZHAN 66 Pro A 14 G3

## Project Overview

This is a NixOS system configuration based on **Nix Flakes**, employing a modular design and integrating **Home Manager** to manage user configurations.

- **System Upgrade Records (2026-08-04)**:
  - **Pot Translation Native Packaging & sgnur-packages Porting**: Created a native `pot-translation` package derivation in `sgnur-packages` using `dpkg-deb` and `autoPatchelfHook`, resolving WebKitGTK 4.0 / libsoup 2.4 deprecation by patching binaries to link against `webkitgtk_4_1` and `libsoup_3`. Added `libayatana-appindicator` and `libappindicator-gtk3` to `LD_LIBRARY_PATH` inside wrapper to fix `dlopen()` runtime panic crash on Wayland/Niri. Exported through `inputs.myRepo` and integrated into Home Manager.

- **System Upgrade Records (2026-08-03)**:
  - **Podman & Libvirtd Configuration Overhaul**: Enhanced `modules/packages/virtualization.nix` with full Podman container runtime support (enabling Docker CLI alias `dockerCompat = true`, Docker socket `/var/run/docker.sock`, and Netavark DNS resolution) and Libvirtd/QEMU virtualization setup (enabling `swtpm` TPM 2.0 emulation, `virt-manager`, `virt-viewer`, `spice`, `podman-compose`, `buildah`, and `skopeo`). Configured and autostarted the libvirt `default` NAT network (`virsh net-autostart default`).
  - **NFS Automount Health Check & Systemd Timer Fix**: Resolved mount point access freezing (`/home/data/_mountpoint_nfs`) caused by active `.automount` units when NFS server is unreachable (port 2049). Removed `x-systemd.automount` from `fileSystems` to prevent `systemd-fstab-generator` auto-enabling, and explicitly defined `systemd.automounts` with `wantedBy = []`. Added a declarative oneshot service `nfs-automount-watcher.service` (using `nc -z`) and `nfs-automount-watcher.timer` (15s interval) in `modules/services/network-storage.nix` to dynamically start/stop the automount unit based on port reachability.
  - **Thunar Default Terminal Integration for Ghostty**: Configured `dotfiles/Thunar/uca.xml` with `ghostty --working-directory=%f` for "Open Terminal Here" action, added `home/programs/thunar.nix` using `mkDotfileLinks`, and set `TERMINAL="ghostty"` in `home.sessionVariables`.
  - **Neovim Clipboard Hardening & Keymaps**: Fixed LazyVim's `VeryLazy` event resetting `vim.opt.clipboard` back to `unnamedplus`. Added `VimEnter`, `VeryLazy`, and `OptionSet` `autocmd` hooks in `home/programs/neovim.nix` to enforce `vim.opt.clipboard = ""`, reserving system clipboard interaction strictly for `<leader>y`, `<leader>d`, and `<leader>p`.
  - **WPS Office HiDPI Scaling & Niri Launcher Fix**: Configured `QT_FONT_DPI=144` in Niri `dotfiles/niri/environment.kdl` and wrapped `wpsoffice-cn` with `symlinkJoin` + `makeWrapper` in Home Manager. Resolved Niri Launcher small UI font issue by dynamically rewriting `.desktop` `Exec` paths to point to the wrapped binaries.

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

## Secrets Disaster Recovery & Key Rotation (SOPS 密钥轮换与恢复指南)

### 场景 1：更换/轮换用户个人 SSH 密钥 (`~/.ssh/id_ed25519`)
当用户个人私钥泄露或主动重新生成用户 SSH 密钥时：

1. **生成新的用户 SSH 密钥对**：
   ```bash
   ssh-keygen -t ed25519 -C "sgnay@outlook.com" -f ~/.ssh/id_ed25519 -N ""
   ```
2. **计算新密钥的 age 公钥**：
   ```bash
   nix-shell -p ssh-to-age --run "ssh-to-age < ~/.ssh/id_ed25519.pub"
   # 输出例如：age1...
   ```
3. **更新配置文件**：
-   将 `common.nix` 中的 `user-public-ssh-keys` 替换为新 SSH 公钥。
-   将 `.sops.yaml` 中的 `&user` 字段替换为上面计算出的 `age1...` 公钥。
4. **重新加密同步 `secrets.yaml`**：
-   导出旧私钥（或已授权的主机私钥）的 age 私钥，并使用 `SOPS_AGE_KEY` 变量驱动 `updatekeys`：
   ```bash
   # 方式 A：通过旧用户私钥的 age 私钥解密并重新加密
   OLD_KEY=$(nix-shell -p ssh-to-age --run "ssh-to-age -private-key -i ~/.ssh/id_ed25519.old")
   SOPS_AGE_KEY="$OLD_KEY" nix-shell -p sops --run "sops updatekeys secrets.yaml -y"

   # 方式 B：通过系统主机私钥解密并重新加密（需要 root 权限读取 host key）
   HOST_KEY=$(sudo nix-shell -p ssh-to-age --run "ssh-to-age -private-key -i /etc/ssh/ssh_host_ed25519_key")
   SOPS_AGE_KEY="$HOST_KEY" nix-shell -p sops --run "sops updatekeys secrets.yaml -y"
   ```

---

### 场景 2：重装系统或更换主机 SSH 密钥 (`/etc/ssh/ssh_host_ed25519_key`)
当重装系统或新设备导致主机 Key 改变，但已备份恢复了用户私钥（`~/.ssh/id_ed25519`）：

1. **计算新主机密钥的 age 公钥**：
   ```bash
   nix-shell -p ssh-to-age --run "ssh-to-age < /etc/ssh/ssh_host_ed25519_key.pub"
   # 输出例如：age1...
   ```
2. **更新 `.sops.yaml`**：
-   将 `.sops.yaml` 中的 `&host` 替换为上面计算的新主机 age 公钥。
3. **使用用户 SSH 私钥同步更新 `secrets.yaml`**：
   ```bash
   USER_KEY=$(nix-shell -p ssh-to-age --run "ssh-to-age -private-key -i ~/.ssh/id_ed25519")
   SOPS_AGE_KEY="$USER_KEY" nix-shell -p sops --run "sops updatekeys secrets.yaml -y"
   ```

---

### 验证与应用
修改完成后，可运行以下命令验证解密：
```bash
USER_KEY=$(nix-shell -p ssh-to-age --run "ssh-to-age -private-key -i ~/.ssh/id_ed25519")
SOPS_AGE_KEY="$USER_KEY" nix-shell -p sops --run "sops decrypt secrets.yaml"
```
确认无误后应用 NixOS 系统配置：
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

