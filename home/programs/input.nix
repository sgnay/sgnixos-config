# home/programs/input.nix — 输入法配置（fcitx5）
# 从 modules/packages/input.nix 迁移到 Home Manager 用户级配置
{
  pkgs,
  lib,
  ...
}:
{
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5.addons = with pkgs; [
      fcitx5-gtk
      fcitx5-nord
      fcitx5-fluent
      catppuccin-fcitx5
      (fcitx5-rime.override {
        rimeDataPkgs = [
          rime-ice
        ];
      })
      fcitx5-vinput
    ];
  };

  # fcitx5 环境变量（Wayland 下 GTK/Qt 使用 text-input 协议，设空值以免干扰）
  home.sessionVariables = {
    XMODIFIERS = "@im=fcitx";
    INPUT_METHOD = "fcitx";
    QT_IM_MODULE = lib.mkForce "";
    GTK_IM_MODULE = lib.mkForce "";
  };

  # fcitx5-vinput 语音输入守护进程。
  # 包自带的服务单元写死 ExecStart=/usr/bin/vinput-daemon，无法在 NixOS 上直接启用，
  # 故此处用真实 store 路径重新声明，并绑定到 fcitx5-daemon 服务（随输入法启停）。
  systemd.user.services."vinput-daemon" = {
    Unit = {
      Description = "fcitx5-vinput voice input daemon";
      PartOf = [ "fcitx5-daemon.service" ];
      After = [ "fcitx5-daemon.service" ];
    };
    Service = {
      ExecStart = "${pkgs.fcitx5-vinput}/bin/vinput-daemon";
      Restart = "on-failure";
    };
    Install = {
      WantedBy = [ "fcitx5-daemon.service" ];
    };
  };
}
