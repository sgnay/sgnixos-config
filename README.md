# sgnixos — NixOS Flake 系统配置

> **主机**: sgnixos · **架构**: x86_64-linux · **硬件**: HP ZHAN 66 Pro A 14 G3 (AMD Ryzen)
>
> **NixOS 26.05 (Yarara)** · **Zen 内核** · **niri + dms-shell (主桌面)** · **COSMIC (备选)**

---

## 🖥️ 项目概述

这是一个基于 **Nix Flakes** 管理的模块化、生产级 NixOS 系统配置，并将 **Home Manager** 作为 NixOS 模块进行集成。

### 近期优化

- **2026-08-03: NFS 按需自动挂载卡死修复与声明式探针 (NFS Automount Health Check & Timer)**
  - **根因消除与移除非必要的 fstab 生成**: 针对配置 `noauto` 但在 NFS 端口 (2049) 不通时访问 `/home/data/_mountpoint_nfs` 依然卡死的问题，移除了 `fileSystems` 中的 `x-systemd.automount` 选项，防止 `systemd-fstab-generator` 自动生成带有开机使能依赖的 autofs 单元。
  - **声明式 Systemd Automount & 定时探针**: 在 `modules/services/network-storage.nix` 中通过 `systemd.automounts` 显式定义 `home-data-_mountpoint_nfs.automount` 并配置 `wantedBy = []`（避免 `masked` 隐患且开机默认不启 autofs）。添加 `nfs-automount-watcher.service` (oneshot `nc` 2049 端口检测) 和 `nfs-automount-watcher.timer` (15s 触发)，端口通畅时自动 `start` 自动挂载，不通时自动 `stop`，零常驻内存开销且彻底解决断网/离网时访问该目录卡死的问题。
- **2026-08-03: Thunar 默认终端联动 Ghostty**
  - **自定义右键动作 (uca.xml)**: 配置 `dotfiles/Thunar/uca.xml` 中的 "Open Terminal Here" 动作命令为 `ghostty --working-directory=%f`。
  - **声明式软链接模块**: 添加 `home/programs/thunar.nix` 结合 `mkDotfileLinks` 将 `dotfiles/Thunar/uca.xml` 自动链接至 `~/.config/Thunar/uca.xml`，并在 `home.sessionVariables` 中全局指定 `TERMINAL="ghostty"`。
- **2026-08-03: Neovim 剪贴板隔离与专有快捷键映射**
  - **LazyVim 剪贴板防覆盖机制**: 针对 LazyVim 异步/VeryLazy 加载重新覆盖 `vim.opt.clipboard` 为 `unnamedplus` 的问题，在 `home/programs/neovim.nix` 中添加 `VimEnter`、`VeryLazy` 及 `OptionSet` 监听钩子，彻底锁死 `vim.opt.clipboard = ""`。
  - **专用系统剪贴板快捷键**: 避免普通 `x/y/d/c` 污染系统剪贴板，配置显式快捷键 `<leader>y` (复制)、`<leader>d` (剪切)、`<leader>p` (粘贴) 与系统剪贴板 `+` 交互。
- **2026-08-03: WPS Office 高分屏适配与 Launcher 动态路径修复**
  - **DPI 环境变量配置**: 在 Niri 的 `dotfiles/niri/environment.kdl` 中配置 `QT_FONT_DPI=144`，全局适配基于 Qt 的 WPS Office 高分屏字体放大。
  - **桌面 Launcher Exec 路径修复**: 针对 WPS 原版 `.desktop` 选项中 `Exec` 硬编码未包装路径导致 Niri Launcher 点击启动丢失环境变量的问题，在 `home/packages/default.nix` 中通过 `symlinkJoin` + `makeWrapper` 重写 `.desktop` 文件中的 `Exec` 路径，保证从桌面启动器与命令行拉起均能正确应用大字体设置。
- **2026-07-23: 通用 FHS 环境配置**
  - **FHS 环境框架 (fhs.nix)**: 基于 `buildFHSEnv` 实现了通用 FHS 隔离环境 `/etc/nixos/fhs.nix`，补齐了常用的 C/C++ 运行时、X11/OpenGL 渲染库及基础开发工具。可使用 `nix-shell /etc/nixos/fhs.nix` 加载并运行未经过 Nix 补丁 (patchelf) 的第三方 Linux 二进制程序与 SDK。
- **2026-07-14: SOPS-Nix 密钥安全重构**
  - **废弃明文 secrets.nix**: 完全移除了之前本地未跟踪且易丢失的明文 `/etc/nixos/secrets.nix`。
  - **SOPS-Nix 安全机制**: 引入 `sops-nix` 加密流程。将主机 SSH Host Key (`/etc/ssh/ssh_host_ed25519_key`) 和用户个人 SSH Key (`~/.ssh/id_ed25519`) 转换并绑定为对应的 `age` 加密实体，既支持系统无感解密，又支持用户日常免密编辑。
  - **动态渲染模板**: 敏感的代理客户端凭据 (如 Xray VLESS outbounds) 归档到 `secrets.yaml` 中，在系统激活时由 `sops-nix` 拼接其他常规变量动态渲染生成 `/run/secrets/rendered/xray-away.json`。Xray 服务启动参数改由动态指向该 RAMFS 安全路径，彻底规避了敏感凭据暴露到全局可读 `/nix/store` 的漏洞。
  - **非敏感变量下沉**: 将 `username`、`email`、`user-public-ssh-keys` 等不具备安全风险的参数解耦下沉到 `common.nix`，使其可安全地被 Git 跟踪和管理。
- **2026-07-14: OMP AI 编程助手集成**
  - **动态链接器包装**: 打包了 `oh-my-pi` (omp) AI 编程助手。由于 Bun 单文件可执行文件将 JS 载荷打包在文件尾部（Trailer 机制），传统的 `patchelf` 会破坏其偏移量。我们通过使用 glibc 动态解释器 (`ld-linux-x86-64.so.2`) 包裹未修改的原始二进制文件解决了此问题。
  - **声明式 NUR Overlay**: 将 `omp` 软件包发布到个人 `sgnur-packages` 仓库，并更新了 Flake 输入的 Overlay 和 Home Manager 的软件包配置。
- **2026-07-13: 架构解耦与 Dotfiles 整理**
  - **软件解耦**: 将 GUI 应用程序从系统级的 `environment.systemPackages` 迁移至 Home Manager，使系统 Profile 更干净。
  - **Dotfiles 管理**: 将符号链接逻辑重构为统一的 `home/lib.nix` 辅助函数 (`mkDotfileLinks`)，使 XDG 配置更加清晰和易维护。
  - **构建健壮性**: 引入 `lib.mkForce` 并增加清理逻辑，解决了 Home Manager 激活时的冲突问题。

---

## 📁 目录结构 (核心)

- `flake.nix`: 系统配置入口，集成 `sops-nix.nixosModules.sops` 模块。
- `configuration.nix`: 最小系统级模块导入。
- `common.nix`: 存放非敏感的系统及用户公共参数。
- `fhs.nix`: 基于 `buildFHSEnv` 的通用 FHS 沙盒隔离环境配置。
- `.sops.yaml`: SOPS 密钥加解密受众规则。
- `secrets.yaml`: 加密保存的敏感数据源。
- `modules/system/`: 系统级基础配置。
- `modules/packages/`: 系统级最小核心工具包。
- `home/`: Home Manager 用户配置。
  - `home.nix`: 用户配置入口。
  - `packages/default.nix`: 用户级应用与工具包集中管理。
  - `programs/`: 模块化的 Home Manager 程序配置 (git, niri, wezterm 等)。
  - `lib.nix`: 统一管理 dotfiles 符号链接的辅助函数。
- `dotfiles/`: 符号链接源文件。

---

## 🚀 快速开始

### 构建与应用

```bash
# 编译并应用当前配置，并设为默认启动项
sudo nixos-rebuild switch --flake /etc/nixos#sgnixos
```

### 密钥日常维护

```bash
# 解密并编辑密文配置文件 (会自动解密并在保存退出时自动重新加密)
nix-shell -p sops --run "sops secrets.yaml"
```

### 密钥轮换、灾备与换机恢复

无论是主动更换/轮换个人 SSH 密钥（`~/.ssh/id_ed25519`），还是重装系统/更换设备导致主机密钥（`/etc/ssh/ssh_host_ed25519_key`）发生改变，完整的密钥更换与恢复步骤均已记录在 [AGENTS.md](file:///etc/nixos/AGENTS.md) 的 **Secrets Disaster Recovery & Key Rotation** 章节。

### 免重启更新配置 (Hot-Reloading)

`dotfiles/` 目录中的配置文件都是通过 `mkOutOfStoreSymlink` 符号链接到系统中的。修改这些配置文件将立即生效（或在应用重启/重新加载后生效），无需重新构建 NixOS。

### FHS 常用排错技巧（查找缺失的动态链接库）

如果在 FHS 环境中运行二进制程序提示 error while loading shared libraries: libXXX.so.Y: cannot open
shared object file：

1. 查缺失库：在 FHS 环境中使用 ldd 检索：
  ldd ./path/to/your/binary

2. 在 Nixpkgs 中搜包：
  nix-locate libXXX.so.Y

- 或使用 command-not-found / nix-search

1. 将查到的 Nix 包名追加到 targetPkgs 列表中即可。
