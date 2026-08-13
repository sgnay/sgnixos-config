# modules/packages/thunar-themes.nix — Thunar 文件管理器美化（安装包）
{
  config,
  pkgs,
  lib,
  ...
}: {
  options.programs.thunar-themes.enable = lib.mkEnableOption "Thunar 文件管理器美化（安装包）";

  config = lib.mkIf config.programs.thunar-themes.enable {
    # Thunar 缩略图支持
    programs.thunar.plugins = with pkgs;
      [
        thunar-archive-plugin
        thunar-volman
      ]
      ++ lib.optionals (pkgs ? tumbler) [tumbler];
  };
}
