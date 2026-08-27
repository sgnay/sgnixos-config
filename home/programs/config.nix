{ config, lib, ... }:
let
  dotfiles = import ../lib.nix { inherit lib config; };
in
{
  xdg.configFile = dotfiles.mkDotfileLinks "" [ "mimeapps.list" ];
}
