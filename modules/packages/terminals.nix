{ config, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    wezterm
    ghostty
    clashtui
  ];
}
