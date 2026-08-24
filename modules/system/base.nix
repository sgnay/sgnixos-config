{ ... }: {
  services.logind.settings = {
    Login.HandlePowerKey = "ignore";
    Login.HandleSuspendKey = "ignore";
    Login.HandleHibernateKey = "ignore";
    Login.HandleLidSwitch = "lock";
    Login.HandleLidSwitchDocked = "lock";
    Login.HandleLidSwitchExternalPower = "lock";
  };

  environment.variables.EDITOR = "nvim";
  environment.variables.VISUAL = "nvim";

  system.stateVersion = "26.05";
}
