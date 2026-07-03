{ config, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    thunar
    megasync
  ];

  # Thunar 文件管理器支持
  programs.thunar.enable = true;
}
