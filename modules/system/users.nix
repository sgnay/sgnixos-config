{ config, pkgs, ... }:
let
  secrets = import ../../secrets.nix;
  userName = secrets.username;
in
{
  programs.fish.enable = true;

  users.users.${userName} = {
    isNormalUser = true;
    description = userName;
    shell = pkgs.fish;
    extraGroups = [ "networkmanager" "wheel" ];
    openssh.authorizedKeys.keys = secrets.user-public-ssh-keys;
    packages = with pkgs; [
      uv
      nodejs
      wget
      aria2
    ];
  };

  security.sudo = {
    enable = true;
    extraRules = [
      {
        groups = [ "wheel" ];
        commands = [
          {
            command = "/run/current-system/sw/bin/nixos-rebuild";
            options = [ "NOPASSWD" ];
          }
          {
            command = "/run/current-system/sw/bin/nix";
            options = [ "NOPASSWD" ];
          }
          {
            command = "/run/current-system/sw/bin/nix-collect-garbage";
            options = [ "NOPASSWD" ];
          }
        ];
      }
    ];
  };
}
