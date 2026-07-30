# Sunlogin remote control client
# Module sourced from sgnur-packages (inputs.myRepo.nixosModules.sunloginclient)
{inputs, ...}: {
  imports = [
    inputs.myRepo.nixosModules.sunloginclient
  ];

  services.sunloginclient.enable = true;
}
