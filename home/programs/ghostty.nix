# home/programs/ghostty.nix — Ghostty 终端配置（可变符号链接）
{ config, lib, pkgs, ... }:
let
  mkLink = config.lib.file.mkOutOfStoreSymlink;
  link = name: { source = mkLink "/etc/nixos/dotfiles/ghostty/${name}"; };
in
{
  home.packages = with pkgs; [ cascadia-code ];

  xdg.configFile = {
    "ghostty/config"            = link "config.ghostty";
    "ghostty/theme.ghostty"     = link "theme.ghostty";
    "ghostty/font.ghostty"      = link "font.ghostty";
    "ghostty/appearance.ghostty" = link "appearance.ghostty";
    "ghostty/binds.ghostty"     = link "binds.ghostty";
    "ghostty/ghostty-shader-playground/public/shaders/cursor_smear.glsl" =
      link "ghostty-shader-playground/public/shaders/cursor_smear.glsl";
    "ghostty/ghostty-shader-playground/public/misc/ghostty_wrapper.glsl" =
      link "ghostty-shader-playground/public/misc/ghostty_wrapper.glsl";
  };
}
