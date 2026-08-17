# home/programs/shell.nix — Fish + Bash + Starship + CLI 工具（可变符号链接）
{
  config,
  lib,
  pkgs,
  ...
}: let
  dotfiles = import ../lib.nix {inherit lib config;};

  commonProxyEnv = "export HTTP_PROXY=http://127.0.0.1:1080 HTTPS_PROXY=http://127.0.0.1:1080 ALL_PROXY=socks5://127.0.0.1:1081 NO_PROXY=localhost,127.0.0.1,::1,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16 http_proxy=$HTTP_PROXY https_proxy=$HTTPS_PROXY all_proxy=$ALL_PROXY no_proxy=$NO_PROXY";
in {
  programs.fish = {
    enable = true;
  };

  programs.bash = {
    enable = true;
    shellAliases = {
      proxy-public = "sudo systemctl start xray-public && ${commonProxyEnv}";
      proxy-home = "sudo systemctl start xray-home && ${commonProxyEnv}";
      proxy-clash = "sudo systemctl start xray-clash && ${commonProxyEnv}";
      proxy-on = "sudo systemctl start xray-none && ${commonProxyEnv}";
      proxy-off = "unset HTTP_PROXY HTTPS_PROXY ALL_PROXY NO_PROXY http_proxy https_proxy all_proxy no_proxy";
    };
  };

  xdg.configFile =
    (
      dotfiles.mkDotfileLinks "fish" [
        "fish_variables"
        "functions"
      ]
    )
    // {
      "fish/config.fish" = {
        source = lib.mkForce (config.lib.file.mkOutOfStoreSymlink "/etc/nixos/dotfiles/fish/config.fish");
      };
    }
    // (dotfiles.mkDotfileLinks "starship" [
      "starship.toml"
    ]);

  programs.starship.enable = true;
}
