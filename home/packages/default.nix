# home/packages/default.nix — 用户级软件包集中管理
{pkgs, ...}: {
  home.packages = with pkgs; [
    # 浏览器
    firefox
    google-chrome

    # 终端
    wezterm
    ghostty
    clashtui
    # nyaterm
    rustconn
    virt-viewer
    helix # 命令行编辑器也属于用户级工具

    # 办公
    joplin-desktop
    thunderbird
    wpsoffice-cn

    # 通讯
    wechat-uos
    qq
    wemeet
    telegram-desktop
    localsend

    # 编辑器
    zed-editor
    lapce

    # 多媒体
    obs-studio
    sunshine
    flameshot
    vlc
    mpv

    # 密码管理器
    keepassxc

    # ai agents
    antigravity
    omp

    # 包装 qqmusic 添加 Electron 标志，改善 Wayland 下字体渲染
    (symlinkJoin {
      name = "qqmusic-wrapped";
      paths = [pkgs.qqmusic];
      buildInputs = [pkgs.makeWrapper];
      postBuild = ''
        wrapProgram $out/bin/qqmusic \
          --add-flags "--ozone-platform-hint=auto --enable-features=UseOzonePlatform" \
          --set ELECTRON_OZONE_PLATFORM_HINT auto
      '';
    })
  ];
}
