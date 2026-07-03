# modules/packages/multimedia.nix — 多媒体软件
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
    qqmusic-wrapped   # QQ 音乐
    obs-studio        # 录屏/直播
    sunshine          # 游戏串流（Moonlight 服务端）
    flameshot         # 截图标注工具
    vlc               # 视频播放器
    mpv               # 轻量视频播放器
  ];
}
