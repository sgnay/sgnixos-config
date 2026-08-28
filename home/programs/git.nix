# programs/git.nix — Git 用户配置
{ ... }:
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
      safe.directory = [ "/etc/nixos" ];
      # 默认 true，会用八进制转义来显示非 ASCII 文件名
      # （如 \344\275\277 是 UTF-8 字节的转义），
      # 防止终端编码不一致导致乱码。
      core.quotePath = false;
      # 多行编辑
      core.editor = "vim";
    };
  };
}
