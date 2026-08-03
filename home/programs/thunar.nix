# home/programs/thunar.nix — Thunar 自定义配置
{
  config,
  lib,
  ...
}: let
  dotfiles = import ../lib.nix {inherit lib config;};
in {
  xdg.configFile = dotfiles.mkDotfileLinks "Thunar" [
    "uca.xml"
  ];
}
