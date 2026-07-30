{pkgs, ...}: let
  common = import ../../common.nix;
in {
  networking = {
    hostName = "sgnixos";
    networkmanager.enable = true;
    nameservers = [
      common.network.primaryDNS
      "4.2.2.1"
    ];
    enableIPv6 = false;
    hosts = {
      "127.0.0.1" = ["localhost"];
      "172.20.26.201" = ["sgnixos"];
    };
    proxy.default = "http://127.0.0.1:1080";
    proxy.noProxy = "127.0.0.1,localhost,${common.network.proxyHost}";
    firewall = {
      enable = true;
      allowedTCPPorts = [
        9090
        9876
      ];
    };
  };
  environment.systemPackages = with pkgs; [rustnet];
}
