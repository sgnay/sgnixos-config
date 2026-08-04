{inputs, ...}: {
  imports = [
    inputs.myRepo.nixosModules.sunloginclient
  ];

  services.sunloginclient.enable = true;
}
