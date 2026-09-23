{...}: {
  services.logind.settings = {
    Login = {
      HandlePowerKey = "ignore";
      HandleSuspendKey = "ignore";
      HandleHibernateKey = "ignore";
      HandleLidSwitch = "lock";
      HandleLidSwitchDocked = "lock";
      HandleLidSwitchExternalPower = "lock";
    };
  };

  environment.variables = {
    EDITOR = "nvim";
    VISUAL = "nvim";
    XMODIFIERS = "@im=fcitx";
    INPUT_METHOD = "fcitx";
    QT_IM_MODULE = "text-input-unstable-v3";
    GTK_IM_MODULE = "text-input-unstable-v3";
  };

  system.stateVersion = "26.05";
}
