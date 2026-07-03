{ config, pkgs, lib, univpn-zip, ... }:

with lib;

let
  cfg = config.services.univpn;

  # ── 从本地 zip 中提取 UniVPN ──────────────────────────
  univpn = pkgs.runCommand "univpn-10781.19.0.1214" {
    nativeBuildInputs = [ pkgs.unzip pkgs.gzip pkgs.binutils ];
  } ''
    unzip -qo ${univpn-zip}
    tail -n +258 univpn-linux-amd64-10781.19.0.1214.run > UniVPN.tar.gz
    mkdir -p $out
    tar -xzf UniVPN.tar.gz -C $out
    chmod +x $out/UniVPN
    chmod +x $out/serviceclient/UniVPNCS
    chmod +x $out/promote/UniVPNPromoteService
    chmod +x $out/UniVPNUpdate
    mkdir -p $out/certificate
  '';

  # ── 系统库路径 ────────────────────────────────────────
  libPath = lib.concatStringsSep ":" [
    "/usr/local/UniVPN/lib"
    "${pkgs.libxcb}/lib"
    "${pkgs.libx11}/lib"
    "${pkgs.libxcb-util}/lib"
    "${pkgs.libxcb-image}/lib"
    "${pkgs.libxcb-keysyms}/lib"
    "${pkgs.libxcb-render-util}/lib"
    "${pkgs.libxcb-wm}/lib"
    "${pkgs.libxkbcommon}/lib"
    "${pkgs.fontconfig.lib}/lib"
    "${pkgs.freetype}/lib"
    "${pkgs.libglvnd}/lib"
    "${pkgs.stdenv.cc.cc.lib}/lib"
    "${pkgs.zstd.out}/lib"
  ];

  # ── Helper 脚本（root 运行，设置 LD_LIBRARY_PATH） ─────
  helper = pkgs.writeShellScriptBin "univpn-helper" ''
    export LD_LIBRARY_PATH="${libPath}"
    exec /usr/local/UniVPN/UniVPN "$@"
  '';

  # ── 启动 wrapper ──────────────────────────────────────
  wrapper = pkgs.writeShellApplication {
    name = "univpn";
    text = ''
      # 从当前用户会话继承关键环境变量（DMS 菜单启动时环境可能 sanitized）
      # writeShellApplication 默认 set -o nounset，临时关闭以安全检测未绑定变量
      set +u
      if [ -z "$DISPLAY" ]; then DISPLAY=:0; fi
      if [ -z "$QT_QPA_PLATFORM" ]; then QT_QPA_PLATFORM=xcb; fi
      if [ -z "$DBUS_SESSION_BUS_ADDRESS" ]; then DBUS_SESSION_BUS_ADDRESS="unix:path=/run/user/$(id -u)/bus"; fi
      if [ -z "$XDG_RUNTIME_DIR" ]; then XDG_RUNTIME_DIR="/run/user/$(id -u)"; fi
      set -u
      export DISPLAY QT_QPA_PLATFORM DBUS_SESSION_BUS_ADDRESS XDG_RUNTIME_DIR

      command -v xhost >/dev/null 2>&1 && xhost +SI:localuser:root 2>/dev/null || true
      exec /run/wrappers/bin/sudo -E ${helper}/bin/univpn-helper "$@"
    '';
  };

  # ── 停止命令 ──────────────────────────────────────────
  stopScript = pkgs.writeShellScriptBin "univpn-stop" ''
    echo "Stopping UniVPN..."
    sudo pkill -9 -f "UniVPN" 2>/dev/null
    sudo pkill -9 -f "UniVPNPromoteService" 2>/dev/null
    sudo pkill -9 -f "UniVPNCS" 2>/dev/null
    sudo rm -f /tmp/29191 /tmp/29192 2>/dev/null
    echo "UniVPN stopped."
  '';

  # ── 重启命令 ──────────────────────────────────────────
  restartScript = pkgs.writeShellScriptBin "univpn-restart" ''
    univpn-stop
    sleep 2
    exec univpn
  '';

  # ── 桌面入口 ──────────────────────────────────────────
  desktopEntry = pkgs.runCommand "univpn.desktop" { } ''
    mkdir -p $out/share/applications
    cat > $out/share/applications/univpn.desktop <<'EOF'
[Desktop Entry]
Name=UniVPN
Name[zh_CN]=UniVPN
Comment=Leagsoft UniVPN Client
Exec=/run/current-system/sw/bin/univpn
Icon=${univpn}/image/ICON.ico
Terminal=false
Type=Application
Categories=Network;
StartupNotify=true
DBusActivatable=false
EOF
  '';

in
{
  options.services.univpn = {
    enable = mkEnableOption "Leagsoft UniVPN client";
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ univpn wrapper desktopEntry pkgs.xhost stopScript restartScript ];

    # 系统激活时安装 UniVPN 到 /usr/local/UniVPN（可写）
    system.activationScripts.univpn = stringAfter [ "binsh" "users" ] ''
      mkdir -p /usr/local/UniVPN
      cp -r ${univpn}/* /usr/local/UniVPN/
      chmod -R u+w /usr/local/UniVPN/
      mkdir -p /usr/local/UniVPN/log /usr/local/UniVPN/certificate
      chmod 777 /usr/local/UniVPN/log
      chmod 755 /usr/local/UniVPN/certificate
      chmod 666 /usr/local/UniVPN/sysconfig.ini 2>/dev/null || true
    '';

    # UniVPN 硬编码调用 /usr/bin/pgrep
    systemd.tmpfiles.rules = [
      "L+ /usr/bin/pgrep - - - - ${pkgs.procps}/bin/pgrep"
    ];

    security.polkit.enable = true;
    security.sudo.wheelNeedsPassword = false;
    security.sudo.extraConfig = ''
      Defaults env_keep += "DISPLAY WAYLAND_DISPLAY XAUTHORITY QT_QPA_PLATFORM"
      %wheel ALL=(ALL) NOPASSWD:SETENV: ${helper}/bin/univpn-helper *
    '';
  };
}