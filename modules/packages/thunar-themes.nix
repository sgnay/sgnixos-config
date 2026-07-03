# modules/packages/thunar-themes.nix — Thunar 文件管理器美化（安装包）
{ config, pkgs, lib, ... }:
{
  options.programs.thunar-themes.enable = lib.mkEnableOption "Thunar 文件管理器美化（安装包）";

  config = lib.mkIf config.programs.thunar-themes.enable {
    # 安装 Catppuccin GTK 主题 + 图标主题（GTK 全局主题配置在 home.nix 中）
    environment.systemPackages = with pkgs; [
      catppuccin-gtk
      adwaita-icon-theme          # StatusNotifier 图标（fcitx5 托盘）
      papirus-icon-theme           # 现代扁平图标集
    ];

    # Thunar 缩略图支持
    programs.thunar.plugins = with pkgs; [
      thunar-archive-plugin
      thunar-volman
    ] ++ lib.optionals (pkgs ? tumbler) [ tumbler ];
  };
}
