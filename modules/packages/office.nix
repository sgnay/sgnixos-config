{ config, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    joplin-desktop
    thunderbird
    wpsoffice-cn
  ];
}
