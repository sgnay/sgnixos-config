# packages/tolaria.nix — Tolaria 桌面知识管理应用
# https://github.com/refactoringhq/tolaria
#
# 使用官方 AppImage 发布版 + .desktop 入口
{ config, pkgs, lib, ... }:
let
  version = "2026.7.1";
  src = pkgs.fetchurl {
    url = "https://github.com/refactoringhq/tolaria/releases/download/v${version}/Tolaria_${version}_amd64.AppImage";
    hash = "sha256-L6ql51KsBNZFEdiyZhMJgRr+bXGKul4iDPcKdNSTzbg=";
  };

  extracted = pkgs.appimageTools.extractType1 { pname = "tolaria"; inherit version src; };

  tolaria = pkgs.stdenv.mkDerivation {
    pname = "tolaria";
    inherit version;

    phases = [ "installPhase" ];

    nativeBuildInputs = with pkgs; [ makeWrapper ];

    installPhase = ''
      mkdir -p $out/bin $out/share/applications $out/share/icons/hicolor/scalable/apps

      # 启动脚本
      makeWrapper ${pkgs.appimage-run}/bin/appimage-run $out/bin/tolaria \
        --run 'cd "$HOME" || cd /tmp || true' \
        --set WEBKIT_DISABLE_COMPOSITING_MODE 1 \
        --add-flags "-w ${extracted}"

      # 桌面入口
      cat > $out/share/applications/tolaria.desktop <<EOF
[Desktop Entry]
Name=Tolaria
Comment=Desktop knowledge-management app
Exec=$out/bin/tolaria
Icon=tolaria
Terminal=false
Type=Application
Categories=Office;Knowledge;
StartupNotify=true
EOF

      # 图标
      cp ${extracted}/usr/share/icons/hicolor/256x256@2/apps/tolaria.png \
        $out/share/icons/hicolor/scalable/apps/tolaria.png 2>/dev/null || \
      cp ${extracted}/Tolaria.png $out/share/icons/hicolor/scalable/apps/tolaria.png 2>/dev/null || true
    '';
  };
in
{
  environment.systemPackages = [ tolaria ];
}