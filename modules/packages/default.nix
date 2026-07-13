# modules/packages/default.nix — 系统软件包集中管理
# 纯包列表集中于此，涉及额外配置的模块（file-manager、input、thunar-themes、tolaria、virtualization）保留各自文件
{ config, pkgs, lib, ... }:
let
  # 包装 qqmusic 添加 Electron 标志，改善 Wayland 下字体渲染
  qqmusic-wrapped = pkgs.symlinkJoin {
    name = "qqmusic-wrapped";
    paths = [ pkgs.qqmusic ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/qqmusic \
        --add-flags "--ozone-platform-hint=auto --enable-features=UseOzonePlatform" \
        --set ELECTRON_OZONE_PLATFORM_HINT auto
    '';
  };
in
{
  environment.systemPackages = with pkgs; [
    # 浏览器
    firefox
    google-chrome

    # 终端
    wezterm
    ghostty
    clashtui
    nyaterm

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
    helix

    # 多媒体
    qqmusic-wrapped
    obs-studio
    sunshine
    flameshot
    vlc
    mpv
  ];
}