# home/packages/default.nix — 用户级软件包集中管理
{ pkgs, ... }: {
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
    oxideterm
    virt-viewer
    helix # 命令行编辑器也属于用户级工具

    # 办公
    joplin-desktop
    thunderbird
    (symlinkJoin {
      name = "wpsoffice-cn-scaled";
      paths = [ wpsoffice-cn ];
      nativeBuildInputs = [ makeWrapper ];
      postBuild = ''
        for prog in wps et wpp wpspdf; do
          if [ -e "$out/bin/$prog" ]; then
            wrapProgram "$out/bin/$prog" \
              --set QT_FONT_DPI "144"
          fi
        done

        for desktop in $out/share/applications/*.desktop; do
          if [ -f "$desktop" ]; then
            rm -f "$desktop"
            cp ${wpsoffice-cn}/share/applications/$(basename "$desktop") "$desktop"
            chmod +w "$desktop"
            sed -i "s|/nix/store/[^/]*/bin/|$out/bin/|g" "$desktop"
          fi
        done
      '';
    })

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
    deadbeef-with-plugins

    # 密码管理器
    keepassxc

    # 命令行/计算器工具
    bc

    # 压缩/解压工具
    unar
    peazip

    # 剪贴板工具
    wl-clipboard

    # ai agents
    antigravity
    omp

    # 包装 qqmusic 添加 Electron 标志，改善 Wayland 下字体渲染
    (symlinkJoin {
      name = "qqmusic-wrapped";
      paths = [ pkgs.qqmusic ];
      buildInputs = [ pkgs.makeWrapper ];
      postBuild = ''
        wrapProgram $out/bin/qqmusic \
          --add-flags "--ozone-platform-hint=auto --enable-features=UseOzonePlatform" \
          --set ELECTRON_OZONE_PLATFORM_HINT auto
      '';
    })
  ];
}
