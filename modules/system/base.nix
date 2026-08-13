{ ... }: {
  services.logind.settings = {
    Login.HandlePowerKey = "ignore";
    Login.HandleSuspendKey = "ignore";
    Login.HandleHibernateKey = "ignore";
    Login.HandleLidSwitch = "ignore";
    Login.HandleLidSwitchDocked = "ignore";
    Login.HandleLidSwitchExternalPower = "ignore";
  };

  environment.variables.EDITOR = "nvim";
  environment.variables.VISUAL = "nvim";

  system.stateVersion = "26.05";
}
