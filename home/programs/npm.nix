# home/programs/npm.nix — npm 全局包配置
# 解决 npx 在 NixOS 上无写入权限的问题
{config, ...}: let
  homeDir = config.home.homeDirectory;
in {
  programs.npm = {
    enable = true;
    settings = {
      prefix = "${homeDir}/.npm-global";
      cache = "${homeDir}/.npm-global/cache";
    };
  };

  # 将 npm 全局 bin 目录加入 PATH
  home.sessionPath = ["${homeDir}/.npm-global/bin"];
}
