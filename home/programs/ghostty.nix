# home/programs/ghostty.nix — Ghostty 终端配置（可变符号链接）
{
  config,
  lib,
  pkgs,
  ...
}: let
  dotfiles = import ../lib.nix {inherit lib config;};
in {
  xdg.configFile =
    (dotfiles.mkDotfileLinks "ghostty" [
      "config.ghostty"
      "theme.ghostty"
      "font.ghostty"
      "appearance.ghostty"
      "binds.ghostty"
    ])
    // (dotfiles.mkDotfileLinks "ghostty/shaders" [
      "cursor_smear.glsl"
      "ghostty_wrapper.glsl"
    ]);
}
