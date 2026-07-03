{ config, pkgs, ... }:
let
  secrets = import ../../secrets.nix;
  userName = secrets.username;
in
{
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      AllowUsers = [ userName ];
    };
    openFirewall = true;
  };
}
