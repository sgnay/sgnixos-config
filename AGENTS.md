# AGENTS.md — NixOS Configuration Guide for AI Agents

> 主机：sgnixos | NixOS 26.05 (Yarara) | x86_64-linux | HP ZHAN 66 Pro A 14 G3

## 项目概述

这是一个基于 **Nix Flakes** 的 NixOS 系统配置，采用模块化设计，集成 **Home Manager** 管理用户配置。

- **主桌面**: niri (scrollable-tiling Wayland compositor) + dms-shell (DankMaterialShell)
- **备选桌面**: COSMIC (System76 Rust 原生 DE)
- **登录管理器**: greetd + ReGreet（图形 GTK4 登录界面，支持会话选择）
- **默认内核**: Zen kernel（优化响应性能），稳定内核可选
- **Home Manager**: 作为 NixOS module 集成，`nixos-rebuild` 时自动应用用户配置

## 目录结构

```
/etc/nixos/
├── flake.nix                    # Flake 入口：inputs + outputs (nixosConfigurations + homeConfigurations)
├── flake.lock
├── configuration.nix            # 主配置：仅 imports（最小化）
├── hardware-configuration.nix   # 自动生成，勿手动修改
├── common.nix                   # 共享变量（网络 DNS/代理）
├── secrets.nix                  # 敏感数据（用户名、SSH 密钥、邮箱）—— 不提交 git
├── secrets.nix.example          # secrets.nix 模板
├── dotfiles/                    # 用户配置文件（纳入 flake 源供 Home Manager 引用）
│   ├── niri/                    #   niri KDL 配置 + dms/ 子目录
│   ├── wezterm/                 #   WezTerm Lua 模块化配置
│   ├── ghostty/                 #   Ghostty 配置 + shader
│   ├── fish/                    #   Fish shell 配置
│   └── starship/                #   Starship 提示符配置
├── modules/                     # NixOS 系统模块
│   ├── desktop/                 #   桌面环境
│   │   ├── niri.nix             #     programs.niri + dms-shell (系统级)
│   │   ├── cosmic.nix           #     COSMIC 桌面（备选，不含 cosmic-greeter）
│   │   ├── fonts.nix            #     字体 + fontconfig 别名
│   │   └── audio.nix            #     PipeWire (无 32 位支持)
│   ├── packages/                #   软件包（systemPackages 分组）
│   │   ├── browsers.nix         #     firefox, google-chrome
│   │   ├── terminals.nix        #     wezterm, ghostty
│   │   ├── office.nix           #     joplin-desktop, wpsoffice-cn
│   │   ├── file-manager.nix     #     thunar + plugins, megasync
│   │   ├── input.nix            #     fcitx5 + rime + 主题 (nord, fluent, catppuccin)
│   │   ├── communication.nix    #     微信 wechat-uos, QQ, 腾讯会议 wemeet, telegram-desktop, localsend
│   │   ├── multimedia.nix       #     vlc, mpv, QQ音乐 qqmusic, obs-studio, sunshine, flameshot
│   │   └── virtualization.nix   #     podman, libvirt, virt-manager
│   ├── services/                #   系统服务
│   │   ├── ssh.nix              #     OpenSSH (密钥认证)
│   │   ├── greetd.nix           #     greetd + ReGreet 登录管理器
│   │   ├── xray.nix             #     Xray VLESS+REALITY 代理
│   │   ├── univpn.nix           #     UniVPN 商业 VPN 客户端（自解压包移植）
│   │   └── network-storage.nix  #     KDE Connect, NFS, Samba, Syncthing
│   └── system/                  #   系统基础
│       ├── base.nix             #     logind, 基础包, keepassxc, file, EDITOR, stateVersion
│       ├── boot.nix             #     systemd-boot (保留 5 代), Zen 默认内核
│       ├── locale.nix           #     时区 Asia/Shanghai, en_US + zh_CN
│       ├── network.nix          #     NetworkManager, 代理, 防火墙
│       ├── nix-config.nix       #     flakes, substituters, allowUnfree, 每周 GC
│       └── users.nix            #     用户 + sudo 规则
└── home/                        # Home Manager 配置
    ├── home.nix                 #   HM 主入口：imports + GTK + sessionVariables
    └── programs/
        ├── git.nix              #   Git 用户配置
        ├── shell.nix            #   Fish + Starship + CLI 工具 (bat/dust/fd/eza/sd/yazi)
        ├── niri.nix             #   niri KDL 部署 + DMS 覆盖系统服务（绑定 niri）+ 生态包
        ├── wezterm.nix          #   WezTerm Lua 模块部署 + fish + 字体
        ├── ghostty.nix          #   Ghostty 配置 + cascadia-code + shader
        └── rime.nix             #   Rime 雾凇拼音 (rime-ice) 安装与配置
```

## 常用命令

```bash
# 构建并测试（不设为默认启动项，立即生效）
sudo nixos-rebuild test --flake /etc/nixos#sgnixos

# 构建并设为下次启动默认
sudo nixos-rebuild boot --flake /etc/nixos#sgnixos

# 构建并立即切换（含 secrets.nix 变更）
sudo nixos-rebuild switch --flake /etc/nixos#sgnixos --update-input secrets-file
# 或使用 fish alias（同上）
rebuild

# 仅 dry-build 验证配置
nixos-rebuild dry-build --flake /etc/nixos#sgnixos

# 更新 flake.lock（全部 inputs）
nix flake update --flake /etc/nixos

# 单独应用 Home Manager（独立模式，非 NixOS 集成时）
home-manager switch --flake /etc/nixos#sgnay

# 检查 DMS 服务状态（绑定 niri.service）
systemctl --user status dms.service
journalctl --user -u dms.service -f

# 代理切换
proxy-home    # 在家模式（走本地 172.20.26.100:1080）
proxy-away    # 外出模式（走 VLESS+REALITY）
proxy-off     # 关闭代理

# 垃圾回收 + 清理旧引导项
sudo nix-collect-garbage -d
sudo nixos-rebuild boot --flake /etc/nixos#sgnixos

# UniVPN 管理
univpn            # 启动 UniVPN VPN 客户端（自动提权）
univpn-stop       # 停止 UniVPN（杀掉所有进程）
univpn-restart    # 重启 UniVPN
```

## 配置约定

1. **模块化原则**: `configuration.nix` 只包含 `imports`，不直接定义配置
2. **敏感数据**: 放在 `secrets.nix`（不跟踪 Git），模板在 `secrets.nix.example`

   ### secrets.nix 管理方式

   `secrets.nix` 作为 flake input（`secrets-file`）引入，受 `flake.lock` 锁定。修改 `secrets.nix` 后需更新 lock 再构建：

   ```bash
   # ✅ 推荐：一步到位（自动更新 secrets-file 的 lock 条目）
   sudo nixos-rebuild switch --flake /etc/nixos#sgnixos --update-input secrets-file
   # 或使用 fish alias
   rebuild
   ```

   ```bash
   # ❌ 错误：只 rebuild 不更新 lock，secrets 不会生效
   sudo nixos-rebuild switch --flake /etc/nixos#sgnixos
   ```

   ```bash
   # ❌ 过度：nix flake update 会查询所有 inputs 的 GitHub API，耗时且没必要
   nix flake update --flake /etc/nixos
   sudo nixos-rebuild switch --flake /etc/nixos#sgnixos
   ```

   > **原理**：`secrets-file` 是 `path: /etc/nixos/secrets.nix` 类型的 flake input，`flake.lock` 记录了该文件的 narHash。`--update-input secrets-file` 告诉 Nix"重新计算这个 input 的 hash"，随后 rebuild 就会使用新文件内容。其他 inputs（nixpkgs、home-manager 等）不受影响。

   **flake.nix 中相关代码**：
   ```nix
   inputs.secrets-file = { url = "path:/etc/nixos/secrets.nix"; flake = false; };
   # 在 outputs 中：
   let secrets = import secrets-file;  # 将 path input 转为 Nix attrset
   ```

3. **共享变量**: 放在 `common.nix`（版本号、网络配置）
3. **共享变量**: 放在 `common.nix`（版本号、网络配置）
4. **dotfiles 即源**: `dotfiles/` 下文件是用户配置的源，Home Manager 通过 `mkOutOfStoreSymlink` 创建**可变符号链接**，编辑源文件即生效，无需 rebuild
5. **nixpkgs 源**: `github:NixOS/nixpkgs/nixos-26.05`（稳定版）
6. **substituters 顺序**: USTC → SJTU → cache.nixos.org（国内镜像优先）
7. **allowUnfree**: 全局开启（`modules/system/nix-config.nix`），Home Manager 不重复设置

## 关键依赖与已知问题

### niri + dms-shell + COSMIC 多桌面共存

- **niri**: NixOS module `programs.niri.enable` 自动配置 xdg-portal, gnome-keyring, wayland session
- **dms-shell**: 通过覆盖 dms-shell 包自带的 `dms.service`，绑定到 `niri.service`（非 `graphical-session.target`），确保只在 niri 下启动，COSMIC 会话不受干扰
- **COSMIC**: `services.desktopManager.cosmic.enable`，使用 greetd 会话选择，不含 cosmic-greeter
- **多会话选择**: greetd + ReGreet 在登录界面列出所有可用桌面（niri / COSMIC）

```
# DMS service 关键配置：绑定 niri，带完整 PATH
systemd.user.services.dms = {
  Unit.PartOf = [ "niri.service" ];
  Unit.After = [ "niri.service" ];
  Install.WantedBy = [ "niri.service" ];
  Service.Environment = "PATH=${quickshell}/bin:${dms-shell}/bin:/run/current-system/sw/bin:${profileDirectory}/bin";
};
```

### 配置文件热更新 (mkOutOfStoreSymlink)

- 所有用户配置（niri/wezterm/ghostty/fish/starship）使用 `config.lib.file.mkOutOfStoreSymlink`
- 编辑 `/etc/nixos/dotfiles/` 下对应文件即生效，无需 `nixos-rebuild`
- 例外：添加/删除包、修改系统模块仍需 rebuild

### Xray 代理系统

- **双模式**: 在家 (`proxy-home` → 本地 172.20.26.100:1080) / 外出 (`proxy-away` → VLESS+REALITY)
- **GUI 客户端**: `clash-verge-rev` 已安装
- **GeoIP 分流**: 国内 IP 直连，海外走代理
- **系统代理**: `network.nix` 中 `proxy.default` 已注释，由 fish 别名按需开启
- **代理 bootstrap 问题**: 系统代理指向未运行 xray 时网络全断，修复步骤：

```
# 1. 临时清空 nix-daemon 代理
sudo systemctl set-environment HTTP_PROXY= HTTPS_PROXY= http_proxy= https_proxy= all_proxy= ALL_PROXY=
sudo systemctl restart nix-daemon

# 2. 执行构建
sudo nixos-rebuild test --flake /etc/nixos#sgnixos

# 3. 构建完成后 nix-daemon 代理自动恢复
```

### 字体 & fontconfig 别名

- **Fira Code 别名**: `fira-code` 包是可变字体 (VF)，缺少 Regular 命名实例，WezTerm 匹配失败
  - **修复**: fontconfig alias `Fira Code → FiraCode Nerd Font`
  - FiraCode Nerd Font 有完整静态字重
- **Chinese Electron 应用乱码（qqmusic/微信等）**: 这些应用请求 Windows/macOS 字体名，需 fontconfig 别名
  - **修复**: `modules/desktop/fonts.nix` 中定义了完整的字体别名表
  - Windows 中文字体 → `WenQuanYi Micro Hei`（Microsoft YaHei, SimHei, DengXian 等）
  - Windows 宋体 → `Noto Serif CJK SC`（SimSun, NSimSun, SimSun-ExtB）
  - macOS 字体 → `WenQuanYi Micro Hei`（-apple-system, PingFang SC/HK/TC, BlinkMacSystemFont）
  - 西文 → `Noto Sans`（Segoe UI, Tahoma, Microsoft Sans Serif）
  - **注意**: Noto Sans CJK SC 是可变字体(VF)，部分旧版 Electron 不兼容，默认无衬线优先用 `WenQuanYi Micro Hei`
- **WPS 符号缺失**: 安装 `corefonts`（Webdings 等微软字体）+ `symbola`（Symbol 补充）
  - Fontconfig 别名：`Wingdings/MT Extra → DejaVu Sans`, `Symbol → Symbola`

### 32 位支持

- `alsa.support32Bit` 已关闭（不需要 Steam/Wine 32 位）
- 若需要 32 位音频：恢复 `modules/desktop/audio.nix` 中此选项（会触发 i686 openblas 编译，无二进制缓存）

### Shell 与 CLI 工具

- **默认 Shell**: fish，通过 `programs.fish.enable` 设置
- **提示符**: starship (gruvbox 主题)
- **fish alias**: cat→bat, du→dust, find→fd, ls→eza, sed→sd
- **其他工具**: yazi (文件管理器), mise (版本管理), zoxide (智能跳转)

### Fish + Home Manager 冲突

- `programs.fish.enable` 与自定义 `config.fish` 的 `xdg.configFile` 冲突
- **修复**: 使用 `lib.mkForce` 覆盖 HM 生成的 config.fish；启用 `home-manager.backupFileExtension = "backup"` 处理文件冲突

### mise 集成

- config.fish 中的 `eval "$(mise activate)"` 需指定 fish shell：`eval "$(mise activate fish)"`
- 否则 mise 输出 bash 语法导致 fish 启动报错

### Qt 应用

- 通过 `qt5ct` + `QT_QPA_PLATFORMTHEME=qt6ct` 管理主题
- `QT_SCALE_FACTOR=1.0`

### 虚拟化

- podman: `virtualisation.podman.enable` + dockerCompat
- libvirt: `virtualisation.libvirtd.enable` + virt-manager
- 用户需加入 `libvirtd` 和 `podman` 组

### 多内核启动 (specialisation)

- Zen 内核为**默认内核**（优化桌面响应），稳定内核作为 specialisation 可选
- systemd-boot 显示：`sgnixos`（Zen）和 `sgnixos (stable-kernel)`（默认内核 6.18.36）
- specialisation 'stable-kernel' 内使用 `lib.mkForce` 覆盖 `boot.kernelPackages`

### systemd-boot

- `configurationLimit = 10`，最多保留 10 个引导项
- `nixos-rebuild` 时自动清理旧项

### greetd + ReGreet 图形登录界面（科幻玻璃风格）

- **ReGreet**: GTK4 图形 greeter，支持背景图片、GTK 主题、时钟显示
- **cage**: 迷你 Wayland 合成器，用于运行 ReGreet（`cage -s -d -- regreet`）
- **主题**: 底层使用 Catppuccin-Mocha 深色主题，外观完全由自定义 CSS 覆盖
- **字体**: **Orbitron**（科幻无衬线）+ **JetBrains Mono**（等宽时钟）—— 通过 `fonts.packages` 安装供 GTK CSS 引用
- **背景**: 使用 COSMIC 壁纸包中的 `tarantula_nebula_nasa_PIA23646.jpg`（狼蛛星云）
- **greeter 用户**: 系统用户，需 `video` 组（cage 访问 DRM）
- **会话列表**: 自动检测 niri / COSMIC 的 `.desktop` 文件
- **模块路径**: `programs.regreet.enable = true`（NixOS 内置模块）
- **配置文件**: 生成至 `/etc/greetd/regreet.toml`，支持 `programs.regreet.settings`
- **自定义 CSS**: 通过 `programs.regreet.extraCss` 注入科幻玻璃风格 CSS（编写于 `modules/services/greetd.nix` 的 `sciFiCss` 变量）

#### 科幻玻璃态（Glassmorphism）设计细节

| 设计元素 | 实现方式 |
|----------|----------|
| **玻璃面板** | `backdrop-filter: blur(24px) saturate(1.4)` + 半透明 `rgba(8, 8, 30, 0.30)` 背景 |
| **霓虹边框** | `border: 1px solid rgba(80, 160, 255, 0.25)` + 内发光 `inset` |
| **呼吸光晕** | `@keyframes panelGlow` — 登录面板蓝色辉光 4s 脉冲 |
| **时钟霓虹** | `#clock_frame label` — 青蓝 `#00e5ff` 等宽字体，`text-shadow` 发光 |
| **按钮脉冲** | `@keyframes btnPulse` — 登录按钮蓝光呼吸 |
| **输入框聚焦** | 聚焦时 `box-shadow: 0 0 12px` 蓝色辉光 |
| **重启/关机** | 悬停→红色渐变辉光（`rgba(255,60,60,0.15)`） |
| **错误提示** | `infobar` 毛玻璃红底 `backdrop-filter: blur(16px)` |
| **问候语** | `✦ SYSTEM ACCESS ✦` 大写 Orbitron 字体，字母间距拉开 |

> **修改 CSS 后**：执行 `nixos-rebuild` 即可生效（CSS 内嵌在 Nix 字符串中，跟随构建）
>
> **默认问候语可选值**：在 `settings.appearance.greeting_msg` 中修改，如 `"SECTOR-7G // AUTHENTICATION REQUIRED"`、`"✦ NEURAL INTERFACE ✦"`、`"ENTER THE GRID"`

### fcitx5 状态栏图标不显示 (Wayland)

- DMS 顶栏使用 StatusNotifier 协议（DBus 系统托盘）
- fcitx5 的 `notificationitem` 插件创建 StatusNotifierItem，DMS 的 `SystemTrayBar.qml` 显示
- 修复步骤：
  1. 安装图标主题 `adwaita-icon-theme`（提供 `input-keyboard-symbolic` 图标）
  2. 在 `~/.config/fcitx5/config` 中设置 `EnabledAddons=notificationitem`
  3. `~/.config/fcitx5/conf/classicui.conf` 中设置 `PreferTextIcon=True` 作为文字兜底

### Rime-ice 雾凇拼音

- `rime-ice` 安装为系统包，数据符号链接到 `~/.local/share/fcitx5/rime/`
- 配置通过 `home/programs/rime.nix` 管理（`home.activation` 创建符号链接和配置文件）
- 默认方案：`rime_ice`（全拼）+ `melt_eng`（英文混输）
- 配置提醒：`rime_ice_suggestion.yaml` 被 `default.custom.yaml` 通过 `__include` 引用
- 部署完成会在 `build/` 目录生成 `rime_ice.prism.bin` 等编译文件

### VSCode 配置（Home Manager）

> 文件：`home/programs/vscode.nix`

Home Manager 的 VSCode 模块在 **26.05** 中将选项移入 profile 作用域：

| 旧选项（已弃用） | 新选项 |
|-------------------|--------|
| `programs.vscode.extensions` | `programs.vscode.profiles.default.extensions` |
| `programs.vscode.userSettings` | `programs.vscode.profiles.default.userSettings` |

**迁移方式**：将 `extensions` 和 `userSettings` 包在 `profiles.default = { ... };` 内即可。

配置内容：
- **包**: `pkgs.vscode-fhs`（FHS 兼容版，支持 C/C++ 等原生扩展）
- **遥测**: 全部关闭（`telemetry.telemetryLevel = "off"`）
- **自动更新**: 关闭（由 Nix 管理版本）
- **字体**: `FiraCode Nerd Font`，连字开启，字号 14
- **主题**: `Default Dark Modern` + `catppuccin.catppuccin-vsc` 扩展
- **扩展**: Python、C/C++、rust-analyzer、Go、Java、GitHub Copilot、Even Better TOML、Markdown All-in-One

### 网络存储服务

- `modules/services/network-storage.nix` 整合了：
  - **KDE Connect** (`kdePackages.kdeconnect-kde`)：手机互联，防火墙开放 1714-1764 端口
  - **NFS** (`nfs-utils`)：NAS `/mnt/sgdata` 按需自动挂载（`x-systemd.automount`, `nolock`, `nofail`, 空闲超时 600s）
  - **Samba** (`samba` + `cifs-utils`)：服务端 + 客户端挂载，自动开放防火墙
    - 使用 Samba 需先设置密码：`sudo smbpasswd -a <username>`
  - **Syncthing** (`services.syncthing`)：文件同步服务

### UniVPN 商业 VPN 客户端

> 文件：`modules/services/univpn.nix` | 安装包：`pkgs/univpn-linux-64-10781.19.0.1214.zip`

UniVPN（深信服 EasyConnect 类 VPN 客户端）是一个商业 Qt5 应用，以 `.run` 自解压脚本形式分发。以下是将其移植到 NixOS 的完整记录，作为后续商业软件打包参考。

#### 打包步骤

1. **分析安装包**：`.zip` → `.run` 自解压脚本 → 提取 gzip 压缩的 tar 数据（跳过 258 行头部）
2. **使用 `runCommand` 提取**：`unzip` → `tail -n +258` → `tar -xzf` → 解压到 `$out`
3. **创建可写运行时目录**：使用 `system.activationScripts` 在系统激活时将文件复制到 `/usr/local/UniVPN`（可写）
4. **设置库路径**：bundled Qt5 库 + 系统 xcb/X11 库，通过 helper 脚本设置 LD_LIBRARY_PATH

#### 关键问题与解决方案

| 问题 | 原因 | 解决方案 |
|------|------|----------|
| 库找不到 | Nix store 输出路径与预期不符 | 使用 `pkgs.fontconfig.lib` 而非 `pkgs.fontconfig`（lib 输出） |
| LD_LIBRARY_PATH 被清空 | sudo 出于安全原因清除它 | 创建 helper 脚本在 root 上下文中设置，通过 `sudo -E` 运行 |
| /usr/bin/pgrep 不存在 | 二进制硬编码调用此路径 | `systemd.tmpfiles.rules` 创建符号链接 |
| Wayland X11 权限 | root 进程无法连接 XWayland | `xhost +SI:localuser:root` 启动时运行 |
| 配置写入失败 | Nix store 是只读的 | 激活脚本复制到 `/usr/local/UniVPN`（可写） |
| sudo 提权 | 需要 root 创建 TUN 设备 | `%wheel NOPASSWD:SETENV:` + `Defaults env_keep` |
| 托盘图标不显示 | xwayland-satellite 不支持 `_NET_SYSTEM_TRAY` | 提供 `univpn-stop`/`univpn-restart` 替代 |

#### 使用的 NixOS 特性

- `pkgs.runCommand` — 自解压包提取
- `pkgs.writeShellScriptBin` / `pkgs.writeShellApplication` — 包装脚本
- `system.activationScripts` — 系统激活时复制文件到可写目录
- `systemd.tmpfiles.rules` — 创建 `/usr/bin/pgrep` 等符号链接
- `security.sudo.extraConfig` — sudoers 免密规则

#### 经验总结（后续商业软件打包参考）

1. **自解压包处理**：`.run` / `.bin` 文件通常是 shell 脚本 + tar.gz 拼接，用 `tail -n +N` 跳过脚本部分
2. **可写运行时目录**：Nix store 只读，需将文件复制到 `/usr/local/`、`/opt/` 或 `~/.local/` 下
3. **`sudo` vs `LD_LIBRARY_PATH`**：sudo 清除敏感环境变量，需用 helper 脚本在提权后设置
4. **硬编码路径**：商业软件常硬编码 `/usr/bin/xxx`、`/usr/local/xxx`，用 `systemd.tmpfiles` 创建符号链接
5. **Wayland 兼容性**：X11-only 应用通过 XWayland 运行，需要 `xhost` 和 DISPLAY 传递
6. **输出包选择**：`fontconfig` 有 `lib`/`bin`/`out` 多个输出，用 `pkgs.fontconfig.lib` 获取库
7. **系统托盘**：xwayland-satellite 不支持 XEmbed 托盘协议，传统 X11 托盘图标在 niri 下无法显示

## 添加新软件包

1. 确定包在哪个分组（packages/*.nix）
2. 添加到对应模块的 `environment.systemPackages`
3. 用户级配置放 `home/programs/` 目录

## 添加新模块

1. 创建 `modules/<category>/<name>.nix`
2. 在 `configuration.nix` 的 `imports` 中添加引用
3. 遵循 `{ config, pkgs, ... }:` 函数签名