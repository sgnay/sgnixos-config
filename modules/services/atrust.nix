# aTrust 深信服零信任客户端
# 外部模块来自 sgnur-packages (inputs.myRepo.nixosModules.atrust)
{inputs, ...}: {
  imports = [
    inputs.myRepo.nixosModules.atrust
  ];

  services.atrust.enable = true;
}
