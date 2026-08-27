# programs/omp.nix — oh-my-pi 用户配置
{ inputs, config, lib, ... }:
let
  dotfiles = import ../lib.nix { inherit lib config; };
in
{
  imports = [ inputs.omp.homeManagerModules.default ];

  home.file = dotfiles.mkDotfileLinks ".omp/agent" [ "config.yml" ];

  programs.omp = {
    enable = true;
    # startup = {
    #   quiet = true; # 静默启动，去除开机 ASCII Banner
    #   showSplash = false; # 禁用启动动画
    # };
  };
}
