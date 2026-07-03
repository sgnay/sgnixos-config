# programs/git.nix — Git 用户配置
{ config, pkgs, ... }:
let
  secrets = import ../../secrets.nix;
in
{
  programs.git = {
    enable = true;
    settings = {
      user.name = secrets.username;
      user.email = secrets.email or "user@example.com";
      init.defaultBranch = "main";
      pull.rebase = true;
    };
  };
}
