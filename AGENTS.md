# AGENTS.md — NixOS Configuration Guide for AI Agents

> 主机：sgnixos | NixOS 26.05 (Yarara) | x86_64-linux | HP ZHAN 66 Pro A 14 G3

## 项目概述

这是一个基于 **Nix Flakes** 的 NixOS 系统配置，采用模块化设计，集成 **Home Manager** 管理用户配置。

- **系统升级记录 (2026-07-14)**:
  - 引入并打包了 `oh-my-pi` (omp) AI 编程助手。由于 Bun 单文件可执行文件采用 Trailer 机制追加打包 JS 脚本，传统 `patchelf` 会破坏段偏移导致其退化为常规 Bun CLI，因此采用了动态加载解释器（Wrapper）方案。
  - 将 `omp` 包成功集成到了本地个人 NUR 仓库 `sgnur-packages` 中，移除了 `/etc/nixos` 的本地包定义，并通过 `myRepo` 动态 Overlay 声明式集成到 Home Manager 包列表。
- **系统升级记录 (2026-07-13)**:
  - 实施了软件包解耦（将 GUI 应用迁移至 Home Manager）。
  - 引入了 `home/lib.nix` 辅助库进行 dotfile 统一管理。
  - 修正了 XDG 子目录路径映射逻辑。

## 目录结构

```
/etc/nixos/
├── flake.nix                    # Flake 入口
├── configuration.nix            # 主配置（仅 imports）
├── modules/                     # NixOS 系统模块
│   ├── desktop/                 # 桌面环境（niri/cosmic/audio/fonts）
│   ├── packages/                # 核心工具包
│   ├── services/                # 系统服务（ssh/greetd/xray/univpn/storage）
│   └── system/                  # 系统基础（boot/locale/network/nix/users）
├── home/                        # Home Manager 配置
│   ├── home.nix                 #   HM 入口
│   ├── lib.nix                  #   共享工具库（如 mkDotfileLinks）
│   ├── packages/                #   用户级应用管理
│   └── programs/                #   模块化程序配置
└── dotfiles/                    # 符号链接源文件
```

## 常用命令

```bash
# 构建并切换
sudo nixos-rebuild switch --flake /etc/nixos#sgnixos

# 检查服务状态
systemctl --user status dms.service
```

## dotfiles 部署逻辑

- 所有用户配置均位于 `dotfiles/` 目录。
- 通过 `home/lib.nix` 中的 `mkDotfileLinks` 函数创建 XDG 符号链接。
- 修改 `dotfiles/` 内容无需重启，应用即可自动更新配置。
- **注意**: 若构建时出现 `*.backup` 冲突，请清理 `~/.config/<program>/*.backup` 文件。

## 注意事项

- `secrets.nix` 不纳入 git 管理。修改后需执行 `rebuild` alias（已配置 `--update-input secrets-file`）。
- `allowUnfree` 已在 Home Manager 中开启，无需额外设置。
