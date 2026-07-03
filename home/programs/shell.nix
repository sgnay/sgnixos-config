# home/programs/shell.nix — Fish + Starship + CLI 工具（可变符号链接）
{ config, lib, pkgs, ... }:
let
  mkLink = config.lib.file.mkOutOfStoreSymlink;
in
{
  programs.fish = {
    enable = true;
  };

  xdg.configFile = {
    "fish/config.fish" = {
      source = lib.mkForce (mkLink "/etc/nixos/dotfiles/fish/config.fish");
    };
    "fish/fish_variables" = {
      source = mkLink "/etc/nixos/dotfiles/fish/fish_variables";
    };
    "fish/functions" = {
      source = mkLink "/etc/nixos/dotfiles/fish/functions";
    };
    "starship/starship.toml" = {
      source = mkLink "/etc/nixos/dotfiles/starship/starship.toml";
    };
  };

  programs.starship.enable = true;

  home.packages = with pkgs; [ bat dust fd eza sd yazi zoxide ];
}
