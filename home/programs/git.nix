# programs/git.nix — Git 用户配置
{
  config,
  pkgs,
  ...
}:
let
  common = import ../../common.nix;
in
{
  programs.git = {
    enable = true;
    settings = {
      user.name = common.username;
      user.email = common.email or "user@example.com";
      init.defaultBranch = "main";
      pull.rebase = true;
      credential.helper = "store";
    };
  };
}
