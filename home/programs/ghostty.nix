# home/programs/ghostty.nix — Ghostty 终端配置（可变符号链接）
{
  config,
  lib,
  pkgs,
  ...
}: let
  dotfiles = import ../lib.nix {inherit lib config;};
in {
  home.packages = with pkgs; [cascadia-code];

  xdg.configFile =
    (
      dotfiles.mkDotfileLinks "ghostty" [
        "config.ghostty"
        "theme.ghostty"
        "font.ghostty"
        "appearance.ghostty"
        "binds.ghostty"
      ]
    )
    // (dotfiles.mkDotfileLinks "ghostty/ghostty-shader-playground/public/shaders" [
      "cursor_smear.glsl"
    ])
    // (dotfiles.mkDotfileLinks "ghostty/ghostty-shader-playground/public/misc" [
      "ghostty_wrapper.glsl"
    ]);
}
