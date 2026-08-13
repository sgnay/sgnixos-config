# home.nix — Home Manager 主配置
{ pkgs, ... }:
let
  common = import ../common.nix;
in
{
  home.username = common.username;
  home.homeDirectory = "/home/${common.username}";

  home.stateVersion = "26.05";

  # 程序配置模块
  imports = [
    ./programs/git.nix
    ./programs/shell.nix
    ./programs/niri.nix
    ./programs/wezterm.nix
    ./programs/ghostty.nix
    ./programs/rime.nix
    ./programs/vscode.nix
    ./programs/neovim.nix
    ./programs/thunar.nix
    ./packages/default.nix # 新增用户级软件包模块
    # ./programs/swayidle.nix # 锁屏和熄屏，dms 有这个功能（但可能会失效），先保留做备用。
  ];

  # 环境变量
  home.sessionVariables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    TERMINAL = "ghostty";
  };

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
