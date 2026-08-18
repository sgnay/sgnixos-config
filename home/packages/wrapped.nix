# home/packages/wrapped.nix — 使用 symlinkJoin 等重新包装的用户级包
# 被 default.nix 导入并加入 home.packages
{
  pkgs,
  unstable,
}:
let
  inherit (pkgs) symlinkJoin makeWrapper;
in
[

  # WeChat 包装：
  # — 设置 QT_IM_MODULE=fcitx 环境变量以支持 fcitx 输入法
  (symlinkJoin {
    name = "wechat-wrapped";
    paths = [ unstable.wechat ];
    nativeBuildInputs = [ makeWrapper ];
    postBuild = ''
      if [ -e "$out/bin/wechat" ]; then
        wrapProgram "$out/bin/wechat" \
          --set QT_FONT_DPI "144" --set QT_IM_MODULE "fcitx"
      fi

      for desktop in $out/share/applications/*.desktop; do
        if [ -f "$desktop" ]; then
          rm -f "$desktop"
          cp ${unstable.wechat}/share/applications/$(basename "$desktop") "$desktop"
          chmod +w "$desktop"
          sed -i "s|^Exec=wechat|Exec=$out/bin/wechat|g" "$desktop"
        fi
      done
    '';
  })

  # WPS Office 包装：
  # — 添加 QT_FONT_DPI 环境变量改善 HiDPI 显示
  # — 添加 QT_IM_MODULE=fcitx 环境变量以支持 fcitx 输入法
  (symlinkJoin {
    name = "wpsoffice-cn-wrapped";
    paths = [ pkgs.wpsoffice-cn ];
    nativeBuildInputs = [ makeWrapper ];
    postBuild = ''
      for prog in wps et wpp wpspdf; do
        if [ -e "$out/bin/$prog" ]; then
          wrapProgram "$out/bin/$prog" \
            --set QT_FONT_DPI "144" --set QT_IM_MODULE "fcitx"
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
]
