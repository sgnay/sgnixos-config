# AGENTS.md — NixOS Configuration Guide for AI Agents

> 主机：sgnixos | NixOS 26.05 (Yarara) | x86_64-linux | HP ZHAN 66 Pro A 14 G3

## 项目概述

这是一个基于 **Nix Flakes** 的 NixOS 系统配置，采用模块化设计，集成 **Home Manager** 管理用户配置。

- **主桌面**: niri (scrollable-tiling Wayland compositor) + dms-shell (DankMaterialShell)
- **备选桌面**: COSMIC (System76 Rust 原生 DE)
- **登录管理器**: greetd + ReGreet（图形 GTK4 登录界面，支持会话选择）
- **默认内核**: Zen kernel（优化响应性能），稳定内核可选
- **开机动画**: Plymouth（breeze 主题）
- **Home Manager**: 作为 NixOS module 集成，`nixos-rebuild` 时自动应用用户配置

## 目录结构

```
/etc/nixos/
├── flake.nix                    # Flake 入口：inputs + outputs (nixosConfigurations + homeConfigurations)
├── flake.lock
├── configuration.nix            # 主配置：仅 imports（最小化，不依赖 inputs）
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
│   │   ├── niri.nix             #     programs.niri + xwayland-satellite + dms-shell（系统级）
│   │   ├── cosmic.nix           #     COSMIC 桌面（备选，不含 cosmic-greeter）
│   │   ├── fonts.nix            #     字体 + fontconfig 别名（含全套 Windows/macOS 映射）
│   │   └── audio.nix            #     PipeWire (无 32 位支持)
│   ├── packages/                #   软件包
│   │   ├── default.nix          #     集中管理：浏览器、终端、办公、通讯、编辑器、多媒体
│   │   ├── file-manager.nix     #     thunar + megasync（thunar 插件/主题在 thunar-themes.nix）
│   │   ├── thunar-themes.nix    #     Thunar 美化包（Catppuccin GTK/Papirus 图标/缩略图）
│   │   ├── input.nix            #     fcitx5 + rime + 主题 (nord, fluent, catppuccin)
│   │   ├── tolaria.nix          #     Tolaria 知识管理桌面应用（AppImage 提取）
│   │   └── virtualization.nix   #     podman, libvirt, virt-manager
│   ├── services/                #   系统服务
│   │   ├── ssh.nix              #     OpenSSH (密钥认证)
│   │   ├── greetd.nix           #     greetd + ReGreet 登录管理器（科幻玻璃 CSS）
│   │   ├── xray.nix             #     Xray VLESS+REALITY 代理（双模式互斥）
│   │   ├── univpn.nix           #     UniVPN 商业 VPN（封装外部模块，遵循"只 imports"约定）
│   │   └── network-storage.nix  #     KDE Connect, NFS, Samba, Syncthing
│   └── system/                  #   系统基础
│       ├── base.nix             #     logind, 基础包（neovim/git/unzip/gcc/nil/statix）, EDITOR, stateVersion
│       ├── boot.nix             #     systemd-boot (保留 5 代), Zen 默认内核, Plymouth (breeze 主题), specialisation 稳定内核
│       ├── locale.nix           #     时区 Asia/Shanghai, en_US + zh_CN
│       ├── network.nix          #     NetworkManager, 系统代理, 防火墙
│       ├── nix-config.nix       #     flakes, substituters, allowUnfree, 每周 GC, store 优化
│       └── users.nix            #     用户 + sudo 规则（含 fish system-wide 启用）
└── home/                        # Home Manager 配置
    ├── home.nix                 #   HM 主入口：imports + GTK（Catppuccin Mocha）+ sessionVariables
    └── programs/
        ├── git.nix              #   Git 用户配置
        ├── shell.nix            #   Fish + Starship + CLI 工具 (bat/dust/fd/eza/sd/yazi/zoxide)
        ├── niri.nix             #   niri KDL 部署 + DMS systemd 服务（绑定 niri）+ 生态包
        ├── wezterm.nix          #   WezTerm Lua 模块部署 + fish + 字体
        ├── ghostty.nix          #   Ghostty 配置 + cascadia-code + shader 文件
        ├── rime.nix             #   Rime 雾凇拼音 (rime-ice) 安装与配置（home.activation）
        ├── vscode.nix           #   VSCode FHS 版 + 扩展（profile 作用域，26.05 兼容）
        └── neovim.nix           #   Neovim + LazyVim 发行版（lazy.nvim 自管理插件）
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

## 配置约定

1. **模块化原则**: `configuration.nix` 只包含 `imports`，不直接定义配置，不依赖 `inputs`
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
4. **dotfiles 即源**: `dotfiles/` 下文件是用户配置的源，Home Manager 通过 `mkOutOfStoreSymlink` 创建**可变符号链接**，编辑源文件即生效，无需 rebuild
5. **nixpkgs 源**: `github:NixOS/nixpkgs/nixos-26.05`（稳定版）
6. **substituters 顺序**: USTC → SJTU → cache.nixos.org（国内镜像优先）
7. **allowUnfree**: 全局开启（`modules/system/nix-config.nix`），Home Manager 不重复设置

## 关键依赖与已知问题

### niri + dms-shell + COSMIC 多桌面共存

- **niri**: NixOS module `programs.niri.enable` 自动配置 xdg-portal, gnome-keyring, wayland session
  - `programs.niri.useNautilus = false`（使用 Thunar 替代 Nautilus 作为文件选择器）
  - 依赖 `xwayland-satellite` 管理 X11 应用
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

### Plymouth 开机动画

- `boot.nix` 中启用：`boot.plymouth.enable = true`，主题为 `breeze`
- `boot.consoleLogLevel = 0` + 内核参数 `quiet` 防止日志泄漏
- **默认使用 BGRT**（从 UEFI 读取 OEM Logo，HP 品牌），如果主板不支持则使用 `breeze` 主题
- 可选主题：`spinner`, `catppuccin-mocha`, `text` 等

### Xray 代理系统

- **双模式**: 在家 (`proxy-home` → 本地 172.20.26.100:1080) / 外出 (`proxy-away` → VLESS+REALITY)
- **GUI 客户端**: `clash-verge-rev` 已安装
- **系统代理**: `network.nix` 中 `proxy.default = "http://127.0.0.1:1080"` 已启用（影响 nix-daemon 等系统服务），fish 别名用于临时切换终端环境
- **外出模式 (xray.service)**: 完整配置，包含 DNS、路由、四个出站
  - **VLESS 出站**（来自 `secrets.nix` 的 `xray-outbounds`）：
    - `proxy-vision` — network `raw`，`xtls-rprx-vision` 流控
    - `proxy-xhttp` — network `xhttp`，`shortId` 独立，默认路由目标
  - **公共出站**: `direct`（freedom+UseIP）、`block`（blackhole）、`local-proxy`（本地网关）
  - **DNS**: 多级 DNS 分流（国内 DNS 直连、海外 DNS 走代理），含 hosts 覆盖
  - **路由**: `domainStrategy: AsIs`，规则包括：
    - 封锁 UDP 443（QUIC 干扰） → `block`
    - `geosite:google` → `proxy-xhttp`
    - 私有地址/国内 DNS IP/`geoip:cn`/`geosite:cn` → `direct`
    - DNS 入口标签分流
- **在家模式 (xray-home.service)**: 只有 `direct` + `local-proxy` + `block`，不含 VLESS 出站
- **互斥启动**: 两 service 通过 `systemd.Conflicts=` 互斥，启动一个自动停另一个（`modules/services/xray.nix`）
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

- **默认 Shell**: fish，通过 `programs.fish.enable` 设置（system 级在 `users.nix`，HM 级在 `shell.nix`）
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
- 用户需加入 `libvirtd` 和 `podman` 组（`users.nix` 中配置）

### 多内核启动 (specialisation)

- Zen 内核为**默认内核**（优化桌面响应），稳定内核作为 specialisation 可选
- systemd-boot 显示：`sgnixos`（Zen）和 `sgnixos (stable-kernel)`（默认内核 6.18.36）
- specialisation 'stable-kernel' 内使用 `lib.mkForce` 覆盖 `boot.kernelPackages`

### systemd-boot

- `configurationLimit = 5`，最多保留 5 个引导项
- `graceful = true`：自动清理旧项
- `canTouchEfiVariables = true`

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
- **光标主题**: Bibata-Modern-Ice
- **电源命令**: 内置 `systemctl reboot` / `systemctl poweroff`
- **自动熄屏**: 登录界面 3 分钟无操作自动关闭显示器（`swayidle` + `wlr-randr`），触摸键盘/鼠标恢复

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
  1. 安装图标主题 `adwaita-icon-theme`（提供 `input-keyboard-symbolic` 图标） — 已安装
  2. 在 `~/.config/fcitx5/config` 中设置 `EnabledAddons=notificationitem`
  3. `~/.config/fcitx5/conf/classicui.conf` 中设置 `PreferTextIcon=True` 作为文字兜底

### Rime-ice 雾凇拼音

- `rime-ice` 安装为系统包，数据通过 `home.activation` 符号链接到 `~/.local/share/fcitx5/rime/`
- 配置通过 `home/programs/rime.nix` 管理（`home.activation` 创建符号链接和 `default.custom.yaml`/`rime_ice.custom.yaml` 配置文件）
- 默认方案：`rime_ice`（全拼）+ `melt_eng`（英文混输）
- 配置提醒：`rime_ice_suggestion.yaml` 被 `default.custom.yaml` 通过 `__include` 引用
- 部署完成会在 `build/` 目录生成 `rime_ice.prism.bin` 等编译文件

### Tolaria 桌面应用（AppImage 提取 + 包装）

> 文件：`modules/packages/tolaria.nix`

Tolaria 是 Tauri 构建的桌面知识管理应用，官方只提供 AppImage 发布版。
打包方式：`fetchurl` 下载 → `appimageTools.extractType1` 提取 → `appimage-run` 运行。

| 问题 | 解决 |
|------|------|
| FUSE 不可用（NixOS 默认不启用） | `extractType1` 静态提取，`appimage-run -w` 用提取目录 |
| bwrap 找不到当前工作目录 | `--run 'cd "$HOME"'` 确保沙箱内可访问 |
| WebKit EGL 初始化失败 | `WEBKIT_DISABLE_COMPOSITING_MODE=1` 软渲染 |
| 运行时缺系统库 | AppImage 自带大部分库，FHS 环境补齐剩余 |

**启动**：终端 `tolaria` 或桌面菜单（Office → Knowledge）

### VSCode 配置（Home Manager）

> 文件：`home/programs/vscode.nix`

配置内容：
- **包**: `pkgs.vscode-fhs`（FHS 兼容版，支持 C/C++ 等原生扩展）
- **遥测**: 全部关闭（`telemetry.telemetryLevel = "off"`）
- **自动更新**: 关闭（由 Nix 管理版本）
- **字体**: `FiraCode Nerd Font`，连字开启，字号 14
- **主题**: `Default Dark Modern` + `catppuccin.catppuccin-vsc` 扩展
- **扩展**: Python、C/C++、rust-analyzer、Go、Java、GitHub Copilot/Chat、Even Better TOML、Markdown All-in-One、Makefile Tools

> **注意**: 当前使用 `profiles.default` 作用域（26.05 新版 API），非弃用的顶级 `extensions`/`userSettings`。

### Neovim + LazyVim 配置（Home Manager）

> 文件：`home/programs/neovim.nix`

- **包**: `pkgs.neovim`（系统级），`lazy-nvim` + `LazyVim`（HM 插件）
- **发行版**: `LazyVim`（lazy.nvim 在首次启动时从 GitHub 自动克隆和管理插件）
- **代理**: 启动时设置 `http://127.0.0.1:1080` 代理环境变量（`GIT_HTTP_PROXY`/`ALL_PROXY`），解决 GitHub 直连问题
- **启动脚本**: 独立 `lazyvim-init.lua` → `~/.config/nvim/lazyvim-init.lua`（`xdg.configFile` 部署），`init.lua` 中 `dofile` 引用
- **Extras 启用**: `lang.nix`, `lang.markdown`, `lang.json`, `coding.blink`, `editor.mini-files`
- **Mason 集成**: `nil_ls` 配置 `mason = false`，避免 Mason 重复安装（由 Nix 系统包提供）
- **颜色主题**: Catppuccin（默认）
- **Nix 工具链**:
  - `nil`（Nix LSP，系统包 + HM 双重供应）
  - `nixfmt`（RFC-style 格式化）
  - `statix`（Nix 代码检查，nvim-lint 依赖）
  - `gcc`（C 编译器，供 Mason 编译原生扩展）
- **性能**: 禁用不常用内置插件，开启缓存
- **自动更新**: 关闭（Nix 管理版本）
- **首次启动**: lazy.nvim 自动从 GitHub 拉取所有插件到 `~/.local/share/nvim/lazy/`

### 网络存储服务

> 文件：`modules/services/network-storage.nix`

- **KDE Connect** (`kdePackages.kdeconnect-kde`)：手机互联，防火墙开放 1714-1764 端口
- **NFS** (`nfs-utils`)：服务端启用 + NAS `/mnt/sgdata` 按需自动挂载
  - 挂载参数：`x-systemd.automount`, `nolock`, `nofail`, `noauto`, 空闲超时 600s, `soft`, `timeo=30`, `retrans=3`
- **Samba** (`samba` + `cifs-utils`)：服务端 + 客户端挂载，自动开放防火墙（137-139, 445），含 `samba-wsdd`（NetBIOS 名称发现）
  - 使用 Samba 需先设置密码：`sudo smbpasswd -a <username>`
- **Syncthing** (`services.syncthing`)：文件同步服务，`overrideFolders = false`, `overrideDevices = false`（保留用户已有配置）

### UniVPN 商业 VPN 客户端

> 模块来源：[sgnur-packages](https://github.com/sgnay/sgnur-packages) 外部 flake repository
> 本地封装：`modules/services/univpn.nix`

UniVPN（深信服 EasyConnect 类 VPN 客户端）的打包与配置已迁移至外部仓库 [sgnur-packages](https://github.com/sgnay/sgnur-packages) 管理。本仓库通过 `modules/services/univpn.nix` 封装外部模块，遵循「configuration.nix 只 imports」的约定。

#### 引入方式

```nix
# flake.nix
inputs.myRepo = {
  url = "github:sgnay/sgnur-packages";            # 发布用
  # url = "path:/home/sgnay/agents/sgnur-packages"; # 本地开发
  inputs.nixpkgs.follows = "nixpkgs";
};

# overlays — 暴露 univpn 包
nixpkgs.overlays = [
  (final: prev: { univpn = inputs.myRepo.packages."${prev.stdenv.hostPlatform.system}".univpn; })
];
```

#### 本地封装模块 (`modules/services/univpn.nix`)

```nix
{ config, pkgs, lib, inputs, ... }:
{
  imports = [
    inputs.myRepo.nixosModules.univpn
  ];

  services.univpn.enable = true;
}
```

**设计要点**:
- 外部模块（`inputs.myRepo.nixosModules.univpn`）的引用和对 `services.univpn.enable` 的启用，都封装在本地模块内
- `inputs` 通过 `flake.nix` 的 `specialArgs` 注入，仅在 `modules/services/univpn.nix` 这一处使用，`configuration.nix` 不直接依赖 `inputs`
- 安装包（`univpn-linux-64-*.zip`）由外部仓库的 flake input 管理，本仓库不包含

完整打包经验（自解压提取、setuid 提权、Qt5 替换等）见 [sgnur-packages 仓库](https://github.com/sgnay/sgnur-packages)。
## 添加新软件包

1. 确定包在哪个分组（packages/*.nix）
2. 添加到对应模块的 `environment.systemPackages`
3. 用户级配置放 `home/programs/` 目录

## 添加新模块

1. 创建 `modules/<category>/<name>.nix`
2. 在 `configuration.nix` 的 `imports` 中添加引用
3. 遵循 `{ config, pkgs, ... }:` 函数签名（如需 `inputs`/`secrets` 等特殊参数，通过 `specialArgs` 注入）