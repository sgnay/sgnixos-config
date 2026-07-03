{ config, pkgs, ... }:
{
  # logind 电源键/盖子行为
  services.logind.settings = {
    Login.HandlePowerKey = "ignore";
    Login.HandleSuspendKey = "ignore";
    Login.HandleHibernateKey = "ignore";
    Login.HandleLidSwitch = "suspend";
    Login.HandleLidSwitchDocked = "ignore";
    Login.HandleLidSwitchExternalPower = "ignore";
  };

  environment.systemPackages = with pkgs; [
    neovim
    git
    unzip
    curl
    adwaita-icon-theme     # 提供 input-keyboard-symbolic 等图标
    keepassxc             # 密码管理器
    file                  # file 命令
  ];

  environment.variables.EDITOR = "nvim";
  environment.variables.VISUAL = "nvim";

  system.stateVersion = "26.05";
}
