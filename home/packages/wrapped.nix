# home/packages/wrapped.nix — 使用 symlinkJoin 等重新包装的用户级包
# 被 default.nix 导入并加入 home.packages
{ pkgs, unstable }:
let
  inherit (pkgs) symlinkJoin makeWrapper;
in
[
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

  # WeChat — fix bwrap CWD error when launched from launcher
  # bwrap wrapper uses `--chdir "$(pwd)"` at runtime. If launcher inherits
  # CWD from a session started in /etc/nixos, that path doesn't exist inside
  # the sandbox (/etc is tmpfs), causing "Can't chdir to /etc/nixos".
  # Solution: wrap the binary to cd to a safe directory first.
  (
    let
      orig = unstable.wechat;
    in
    pkgs.stdenv.mkDerivation {
      name = "wechat-wrapped";
      nativeBuildInputs = [ pkgs.makeWrapper ];
      phases = [ "installPhase" ];
      installPhase = ''
          mkdir -p $out/bin $out/share/applications

          # Use makeWrapper to create a proper wrapper script (no shebang indent issues)
          makeWrapper '${orig}/bin/wechat' "$out/bin/wechat" \
            --run 'cd "$HOME" 2>/dev/null || cd /tmp 2>/dev/null || cd /' \
            --run 'if [ -z "$DISPLAY" ]; then for d in /tmp/.X11-unix/X[0-9]*; do [ -S "$d" ] && [ -O "$d" ] && export DISPLAY=":''${d##*X}" && break; done; fi'

          # Copy and fix desktop file to point to our wrapper
          cp '${orig}/share/applications/wechat.desktop' "$out/share/applications/wechat.desktop"
          chmod +w "$out/share/applications/wechat.desktop"
          substituteInPlace "$out/share/applications/wechat.desktop" \
            --replace-fail "Exec=wechat" "Exec=$out/bin/wechat"
      '';
    }
  )
]
