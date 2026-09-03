# home/packages/default.nix — 用户级软件包集中管理
# 所有用户级包（home.packages）统一在此声明，按功能分类
# 自定义打包（symlinkJoin 等）在 wrapped.nix 中
{
  pkgs,
  unstable,
  inputs,
  ...
}: {
  home.packages = with pkgs;
    [
      # ========== 浏览器 ==========
      firefox
      google-chrome

      # ========== 串口/终端工具 ==========
      picocom
      minicom
      screen
      ghostty
      rustconn
      oxideterm
      nushell
      putty
      nyaterm

      # ========== 输入法 ==========
      qt6Packages.fcitx5-configtool

      # ========== 办公 ==========
      drawio
      kdePackages.okular # KDE 文档与 PDF 阅读器
      nomacs
      thunderbird
      sunshine

      # ========== 通讯/社交 ==========
      unstable.qq
      wemeet
      telegram-desktop
      localsend

      # ========== 编辑器/IDE ==========
      unstable.zed-editor-fhs
      lapce
      helix # 命令行编辑器
      velotype
      joplin-desktop

      # ========== 多媒体 ==========
      obs-studio
      unstable.shotcut
      vlc
      mpv
      deadbeef
      netease-cloud-music-gtk
      unstable.qqmusic
      unstable.ffmpeg

      # ========== 密码管理器 ==========
      keepassxc

      # ========== 开发工具 / Rust 工具链 ==========
      cargo
      clippy
      rustc
      rustfmt
      mold
      clang
      pkg-config
      openssl
      alsa-lib
      python3

      # ========== 压缩/解压 ==========
      unar
      peazip
      unrar

      # ========== 剪贴板工具 ==========
      wl-clipboard

      # ========== AI 代理 ==========
      goose
      goose-desktop
      deepseek-reasonix
      unstable.mcp-nixos

      # ========== 翻译工具 ==========
      simple-translation
      simple-ocr

      # ========== CLI 工具 ==========
      bat
      dust
      fd
      fzf
      eza
      sd
      yazi
      zoxide
      jq
      dig
      unstable.rustnet
      # unstable.wltr  # missing from unstable
      # ========== 桌面环境&工具 ==========
      cosmic-icons
      pop-icon-theme
      cosmic-wallpapers
      cosmic-screenshot
      cosmic-randr
      xdg-desktop-portal-gtk
      xwayland-satellite # niri 的内置 X11 兼容层运行时依赖
      dms-shell
      quickshell # DMS 运行时依赖
      vicinae # 应用启动器
      fsearch # 文件搜索
      satty # 截图标注
      flameshot # 截图工具
      swaybg # 壁纸
      libsForQt5.qt5ct
      cursor-clip
      kdePackages.polkit-kde-agent-1 # 身份认证 UI
      tesseract # OCR 识别引擎

      # ========== 文件管理 ==========
      nautilus
      megasync
      adwaita-icon-theme # StatusNotifier 图标（fcitx5 托盘）也提供 input-keyboard-symbolic 等

      # ========== 网络代理 ==========
      xray
      unstable.v2ray-geoip
      unstable.v2ray-domain-list-community
      clash-verge-rev
      unstable.sing-box
      unstable.sing-geoip
    ]
    # 导入自定义重新包装的包（symlinkJoin 等）
    ++ (import ./wrapped.nix {inherit pkgs unstable inputs;});
}
