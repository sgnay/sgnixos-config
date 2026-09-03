# home.nix — Home Manager 主配置
{ pkgs, common, ... }:
{
  home.username = common.username;
  home.homeDirectory = "/home/${common.username}";

  home.stateVersion = "26.05";

  # 程序配置模块
  imports = [
    ./programs/config.nix # 公共配置和临时配置
    ./packages/default.nix # 用户级软件包模块
    ./programs/git.nix
    ./programs/shell.nix
    ./programs/niri.nix
    ./programs/wezterm.nix
    ./programs/ghostty.nix
    ./programs/rime.nix
    ./programs/vscode.nix
    ./programs/neovim.nix
    ./programs/npm.nix
    ./programs/omp.nix
  ];

  # 环境变量

  # GTK 主题（Catppuccin Mocha + Papirus Dark 图标）
  gtk = {
    enable = true;
    theme = {
      name = "Catppuccin-Mocha";
      package = pkgs.catppuccin-gtk;
    };
    iconTheme = {
      name = "Papirus-Dark";
      package = pkgs.papirus-icon-theme;
    };
    cursorTheme = {
      name = "Bibata-Modern-Ice";
      package = pkgs.bibata-cursors;
      size = 24;
    };
  };

  programs.home-manager.enable = true;
}
