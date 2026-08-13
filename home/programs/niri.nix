# home/programs/niri.nix — niri + dms-shell 用户配置
{
  config,
  lib,
  pkgs,
  ...
}: let
  dotfiles = import ../lib.nix {inherit lib config;};
in {
  home.packages = with pkgs; [
    dms-shell
    quickshell # DMS 运行时依赖
    vicinae # 应用启动器
    fsearch # 文件搜索
    satty # 截图标注
    swaybg # 壁纸
    libsForQt5.qt5ct
    nushell
    cursor-clip
  ];

  # niri 配置 — 可变符号链接，编辑 /etc/nixos/dotfiles/niri/ 即生效
  xdg.configFile =
    (dotfiles.mkDotfileLinks "niri" [
      "config.kdl"
      "environment.kdl"
      "input.kdl"
      "layout.kdl"
      "animations.kdl"
      "window-rule.kdl"
      "layer-rule.kdl"
      "recent-windows.kdl"
      "spawn-at-startup.kdl"
    ])
    // (dotfiles.mkDotfileLinks "niri/dms" [
      "colors.kdl"
      "layout.kdl"
      "alttab.kdl"
      "binds.kdl"
      "outputs.kdl"
      "cursor.kdl"
      "windowrules.kdl"
      "wpblur.kdl"
    ])
    // {
      "qt5ct/qt5ct.conf".text = ''
        [Appearance]
        style=Fusion
        custom_palette=true
      '';
    };

  # DMS systemd 服务 — 绑定到 niri.service
  systemd.user.services.dms = {
    Unit = {
      Description = "Dank Material Shell (DMS)";
      PartOf = ["niri.service"];
      After = ["niri.service"];
    };
    Service = {
      ExecStart = "${pkgs.dms-shell}/bin/dms run";
      Restart = "on-failure";
      RestartSec = 3;
      Environment = "PATH=${pkgs.quickshell}/bin:${pkgs.dms-shell}/bin:/run/current-system/sw/bin:${config.home.profileDirectory}/bin";
    };
    Install = {
      WantedBy = ["niri.service"];
    };
  };
}
