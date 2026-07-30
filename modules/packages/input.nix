{
  pkgs,
  lib,
  ...
}: {
  i18n.inputMethod = {
    enable = true;
    type = "fcitx5";
    fcitx5.addons = with pkgs; [
      fcitx5-rime
      fcitx5-gtk
      fcitx5-nord
      fcitx5-fluent
      catppuccin-fcitx5
    ];
  };

  # fcitx5 环境变量（Wayland 下 GTK/Qt 使用 text-input 协议，设空值以免干扰）
  environment.variables = {
    GTK_IM_MODULE = lib.mkForce "";
    QT_IM_MODULE = lib.mkForce "";
    XMODIFIERS = "@im=fcitx";
  };

  # fcitx5 配置工具和 rime-ice 词库
  environment.systemPackages = with pkgs; [
    qt6Packages.fcitx5-configtool
    rime-ice # 雾凇拼音词库
  ];
}
