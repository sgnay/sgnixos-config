{pkgs, ...}: {
  # logind 电源键/盖子行为
  services.logind.settings = {
    Login.HandlePowerKey = "ignore";
    Login.HandleSuspendKey = "ignore";
    Login.HandleHibernateKey = "ignore";
    Login.HandleLidSwitch = "ignore";
    Login.HandleLidSwitchDocked = "ignore";
    Login.HandleLidSwitchExternalPower = "ignore";
  };

  environment.systemPackages = with pkgs; [
    neovim
    git
    unzip
    curl
    adwaita-icon-theme # 提供 input-keyboard-symbolic 等图标
    file               # file 命令
    gcc                # C 编译器（Mason 等工具依赖）
    nil                # Nix LSP（系统级可用）
    statix             # Nix 代码检查（nvim-lint 依赖）
    tree
  ];

  environment.variables.EDITOR = "nvim";
  environment.variables.VISUAL = "nvim";

  system.stateVersion = "26.05";
}
