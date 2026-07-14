# sgnixos — NixOS Flake 系统配置

> **主机**: sgnixos · **架构**: x86_64-linux · **硬件**: HP ZHAN 66 Pro A 14 G3 (AMD Ryzen)
>
> **NixOS 26.05 (Yarara)** · **Zen 内核** · **niri + dms-shell (主桌面)** · **COSMIC (备选)**

---

## 🖥️ 项目概述

这是一个基于 **Nix Flakes** 管理的模块化、生产级 NixOS 系统配置，并将 **Home Manager** 作为 NixOS 模块进行集成。

### 近期优化
- **2026-07-14: OMP AI 编程助手集成**
  - **动态链接器包装**: 打包了 `oh-my-pi` (omp) AI 编程助手。由于 Bun 单文件可执行文件将 JS 载荷打包在文件尾部（Trailer 机制），传统的 `patchelf` 会破坏其偏移量。我们通过使用 glibc 动态解释器 (`ld-linux-x86-64.so.2`) 包裹未修改的原始二进制文件解决了此问题。
  - **声明式 NUR Overlay**: 将 `omp` 软件包发布到个人 `sgnur-packages` 仓库，并更新了 Flake 输入的 Overlay 和 Home Manager 的软件包配置。
- **2026-07-13: 架构解耦与 Dotfiles 整理**
  - **软件解耦**: 将 GUI 应用程序从系统级的 `environment.systemPackages` 迁移至 Home Manager，使系统 Profile 更干净。
  - **Dotfiles 管理**: 将符号链接逻辑重构为统一的 `home/lib.nix` 辅助函数 (`mkDotfileLinks`)，使 XDG 配置更加清晰和易维护。
  - **构建健壮性**: 引入 `lib.mkForce` 并增加清理逻辑，解决了 Home Manager 激活时的冲突问题。

---

## 📁 目录结构 (核心)

- `flake.nix`: 系统配置入口。
- `configuration.nix`: 最小系统级模块导入。
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

### 免重启更新配置 (Hot-Reloading)
`dotfiles/` 目录中的配置文件都是通过 `mkOutOfStoreSymlink` 符号链接到系统中的。修改这些配置文件将立即生效（或在应用重启/重新加载后生效），无需重新构建 NixOS。
