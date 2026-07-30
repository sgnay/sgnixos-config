# UniVPN 商业 VPN 客户端
# 外部模块来自 sgnur-packages (inputs.myRepo.nixosModules.univpn)
{inputs, ...}: {
  imports = [
    inputs.myRepo.nixosModules.univpn
  ];

  services.univpn.enable = true;
}
