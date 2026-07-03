# home/programs/niri.nix — niri + dms-shell 用户配置
{ config, lib, pkgs, ... }:
let
  mkLink = config.lib.file.mkOutOfStoreSymlink;
  niriLink = name: { source = mkLink "/etc/nixos/dotfiles/niri/${name}"; };
  dmsLink  = name: { source = mkLink "/etc/nixos/dotfiles/niri/dms/${name}"; };
in
{
  home.packages = with pkgs; [
    dms-shell
    quickshell           # DMS 运行时依赖
    vicinae              # 应用启动器
    fsearch              # 文件搜索
    satty                # 截图标注
    swaybg               # 壁纸
    bibata-cursors       # 光标主题
    kdePackages.polkit-kde-agent-1
    libsForQt5.qt5ct
    nushell
    cursor-clip
  ];

  # niri 配置 — 可变符号链接，编辑 /etc/nixos/dotfiles/niri/ 即生效
  xdg.configFile = {
    "niri/config.kdl"            = niriLink "config.kdl";
    "niri/environment.kdl"       = niriLink "environment.kdl";
    "niri/input.kdl"             = niriLink "input.kdl";
    "niri/layout.kdl"            = niriLink "layout.kdl";
    "niri/animations.kdl"        = niriLink "animations.kdl";
    "niri/window-rule.kdl"       = niriLink "window-rule.kdl";
    "niri/layer-rule.kdl"        = niriLink "layer-rule.kdl";
    "niri/recent-windows.kdl"    = niriLink "recent-windows.kdl";
    "niri/spawn-at-startup.kdl"  = niriLink "spawn-at-startup.kdl";
    "niri/dms/colors.kdl"       = dmsLink "colors.kdl";
    "niri/dms/layout.kdl"       = dmsLink "layout.kdl";
    "niri/dms/alttab.kdl"       = dmsLink "alttab.kdl";
    "niri/dms/binds.kdl"        = dmsLink "binds.kdl";
    "niri/dms/outputs.kdl"      = dmsLink "outputs.kdl";
    "niri/dms/cursor.kdl"       = dmsLink "cursor.kdl";
    "niri/dms/windowrules.kdl"  = dmsLink "windowrules.kdl";
    "niri/dms/wpblur.kdl"       = dmsLink "wpblur.kdl";
  };

  # DMS systemd 服务 — 绑定到 niri.service
  # 只在 niri 启动时跟着启动，不干扰 COSMIC 会话
  # 使用完整定义（替换包自带的 dms.service），确保 PATH 包含 quickshell
  systemd.user.services.dms = {
    Unit = {
      Description = "Dank Material Shell (DMS)";
      PartOf = [ "niri.service" ];
      After = [ "niri.service" ];
    };
    Service = {
      ExecStart = "${pkgs.dms-shell}/bin/dms run";
      Restart = "on-failure";
      RestartSec = 3;
      Environment = "PATH=${pkgs.quickshell}/bin:${pkgs.dms-shell}/bin:/run/current-system/sw/bin:${config.home.profileDirectory}/bin";
    };
    Install = {
      WantedBy = [ "niri.service" ];
    };
  };

  home.pointerCursor = {
    name = "Bibata-Modern-Ice";
    package = pkgs.bibata-cursors;
    size = 24;
    gtk.enable = true;
  };

  xdg.configFile."qt5ct/qt5ct.conf".text = ''
    [Appearance]
    style=Fusion
    custom_palette=true
  '';

}

