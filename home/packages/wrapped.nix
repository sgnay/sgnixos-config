# home/packages/wrapped.nix — 使用 symlinkJoin 等重新包装的用户级包
# 被 default.nix 导入并加入 home.packages
{
  pkgs,
  unstable,
  inputs,
}: let
  inherit (pkgs) symlinkJoin makeWrapper;
in [
  # WeChat 包装：
  # — 设置 QT_IM_MODULE=fcitx 环境变量以支持 fcitx 输入法
  (symlinkJoin {
    name = "wechat-wrapped";
    paths = [unstable.wechat];
    nativeBuildInputs = [makeWrapper];
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
    paths = [pkgs.wpsoffice-cn];
    nativeBuildInputs = [makeWrapper];
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

  # Ferrite 包装：
  # — 注入 Wayland / OpenGL / Vulkan / X11 运行时动态链接库（解决 winit 运行时 NoWaylandLib 错误）
  # — 安装桌面启动项 (.desktop) 与应用图标
  (let
    runtimeLibs = with pkgs; [
      wayland
      libxkbcommon
      libGL
      vulkan-loader
      libx11
      libxcursor
      libxi
      libxrandr
      libxcb
      fontconfig
      freetype
    ];
  in
    symlinkJoin {
      name = "ferrite-wrapped";
      paths = [pkgs.ferrite];
      nativeBuildInputs = [makeWrapper];
      postBuild = ''
        wrapProgram "$out/bin/ferrite" \
          --prefix LD_LIBRARY_PATH : "${pkgs.lib.makeLibraryPath runtimeLibs}"

        mkdir -p $out/share/applications $out/share/icons/hicolor
        if [ -d "${inputs.ferrite}/assets/icons/linux" ]; then
          cp ${inputs.ferrite}/assets/icons/linux/ferrite.desktop $out/share/applications/
          sed -i "s|^Exec=ferrite|Exec=$out/bin/ferrite|g" $out/share/applications/ferrite.desktop
          for size in 16x16 32x32 48x48 64x64 128x128 256x256 512x512; do
            if [ -f "${inputs.ferrite}/assets/icons/linux/$size/ferrite.png" ]; then
              mkdir -p $out/share/icons/hicolor/$size/apps
              cp "${inputs.ferrite}/assets/icons/linux/$size/ferrite.png" $out/share/icons/hicolor/$size/apps/
            fi
          done
        fi
      '';
    })
]
