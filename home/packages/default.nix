# home/packages/default.nix — 用户级软件包集中管理
{ pkgs, unstable, ... }: {
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
    velotype
    virt-viewer
    fish

    # 字体
    cascadia-code
    jetbrains-mono
    wqy_zenhei
    fira-code

    # 输入法
    rime-ice

    # 办公
    drawio
    kdePackages.okular # KDE 文档与 PDF 阅读器
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
    unstable.qq
    wechat
    wemeet
    telegram-desktop
    localsend

    # 编辑器
    unstable.zed-editor-fhs
    lapce
    helix # 命令行编辑器

    # 多媒体
    obs-studio
    sunshine
    flameshot
    vlc
    mpv
    nomacs
    deadbeef
    netease-cloud-music-gtk
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

    # 密码管理器
    keepassxc

    # 开发工具 / Rust 工具链
    cargo
    rustc
    pkg-config
    openssl
    alsa-lib

    # 命令行/计算器工具
    bc

    # 压缩/解压工具
    unar
    peazip
    unrar

    # 剪贴板工具
    wl-clipboard

    # ai agents
    unstable.antigravity-cli
    unstable.antigravity-ide-fhs
    unstable.pi-coding-agent
    omp
    goose
    goose-desktop

    # 翻译工具
    simple-translation

    # 其它
    ## neovim 依赖
    nil # Nix LSP
    nixfmt # Nix 格式化（RFC-style）
    ## 身份认证 UI，不记得在哪依赖了，先留着
    kdePackages.polkit-kde-agent-1
  ];
}
