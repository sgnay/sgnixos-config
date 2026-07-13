# home/programs/shell.nix — Fish + Starship + CLI 工具（可变符号链接）
{
  config,
  lib,
  pkgs,
  ...
}: let
  dotfiles = import ../lib.nix {inherit lib config;};
in {
  programs.fish = {
    enable = true;
  };

  xdg.configFile =
    (
      dotfiles.mkDotfileLinks "fish" [
        "fish_variables"
        "functions"
      ]
    )
    // {
      "fish/config.fish" = {
        source = lib.mkForce (config.lib.file.mkOutOfStoreSymlink "/etc/nixos/dotfiles/fish/config.fish");
      };
    }
    // (dotfiles.mkDotfileLinks "starship" [
      "starship.toml"
    ]);

  programs.starship.enable = true;

  home.packages = with pkgs; [
    bat
    dust
    fd
    eza
    sd
    yazi
    zoxide
    starship
  ];
}
