{ ... }:
let
  common = import ../../common.nix;
in
{
  networking = {
    hostName = "sgnixos";
    networkmanager.enable = true;
    nameservers = [
      common.network.primaryDNS
      "4.2.2.1"
    ];
    enableIPv6 = true;
    hosts = {
      "127.0.0.1" = [ "localhost" ];
      "172.20.26.201" = [ "sgnixos" ];
    };
    proxy.default = "http://127.0.0.1:1080";
    proxy.noProxy = "127.0.0.1,localhost,${common.network.proxyHost}";
    firewall = {
      enable = true;
      allowedTCPPorts = [
        2049
        22000
        53317
      ];
      allowedTCPPortRanges = [
        {
          from = 1714;
          to = 1764;
        }
      ];
      allowedUDPPortRanges = [
        {
          from = 1714;
          to = 1764;
        }
      ];
    };
  };
}
