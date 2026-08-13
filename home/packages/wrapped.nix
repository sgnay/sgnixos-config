# home/packages/wrapped.nix — 使用 symlinkJoin 等重新包装的用户级包
# 被 default.nix 导入并加入 home.packages
{pkgs}: let
  inherit (pkgs) symlinkJoin makeWrapper;
in [
  # WPS Office — 添加 QT_FONT_DPI 环境变量改善 HiDPI 显示
  (symlinkJoin {
    name = "wpsoffice-cn-scaled";
    paths = [ pkgs.wpsoffice-cn ];
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
          cp ${pkgs.wpsoffice-cn}/share/applications/$(basename "$desktop") "$desktop"
          chmod +w "$desktop"
          sed -i "s|/nix/store/[^/]*/bin/|$out/bin/|g" "$desktop"
        fi
      done
    '';
  })

  # QQ音乐 — 添加 Electron 标志改善 Wayland 下字体渲染
  (symlinkJoin {
    name = "qqmusic-wrapped";
    paths = [ pkgs.qqmusic ];
    buildInputs = [ makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/qqmusic \
        --add-flags "--ozone-platform-hint=auto --enable-features=UseOzonePlatform" \
        --set ELECTRON_OZONE_PLATFORM_HINT auto
    '';
  })
]