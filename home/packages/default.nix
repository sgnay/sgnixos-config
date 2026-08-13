# home/packages/default.nix — 用户级软件包集中管理
# 所有用户级包（home.packages）统一在此声明，按功能分类
# 自定义打包（symlinkJoin 等）在 wrapped.nix 中
{ pkgs, unstable, ... }: {
  home.packages =
    with pkgs;
    [
      # ========== 浏览器 ==========
      firefox
      google-chrome

      # ========== 串口/终端工具 ==========
      picocom
      minicom
      screen
      wezterm
      ghostty
      rustconn
      oxideterm
      nushell
      putty
      # nyaterm

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
      wechat
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
      vlc
      mpv
      deadbeef
      netease-cloud-music-gtk

      # ========== 密码管理器 ==========
      keepassxc

      # ========== 开发工具 / Rust 工具链 ==========
      cargo
      rustc
      pkg-config
      openssl
      alsa-lib

      # ========== 压缩/解压 ==========
      unar
      peazip
      unrar

      # ========== 剪贴板工具 ==========
      wl-clipboard

      # ========== AI 代理 ==========
      unstable.antigravity-cli
      unstable.antigravity-ide-fhs
      unstable.pi-coding-agent
      omp
      goose
      goose-desktop

      # ========== 翻译工具 ==========
      simple-translation

      # ========== CLI 工具 ==========
      bat
      dust
      fd
      eza
      sd
      yazi
      zoxide
      starship

      # ========== 桌面环境&工具 ==========
      cosmic-icons
      pop-icon-theme
      cosmic-wallpapers
      cosmic-screenshot
      cosmic-randr
      xdg-desktop-portal-gtk
      # xwayland-satellite # xwayland 支持(可能是多余的，但是先保留)
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
      kdePackages.kdeconnect-kde # 手机-电脑互联

      # ========== 文件管理 ==========
      thunar
      megasync
      catppuccin-gtk # GTK 主题
      adwaita-icon-theme # StatusNotifier 图标（fcitx5 托盘）也提供 input-keyboard-symbolic 等
      papirus-icon-theme # 现代扁平图标集

      # ========== 网络代理 ==========
      xray
      v2ray-geoip
      v2ray-domain-list-community
      clash-verge-rev
      clashtui
    ]

    # 导入自定义重新包装的包（symlinkJoin 等）
    ++ (import ./wrapped.nix { inherit pkgs; });
}
