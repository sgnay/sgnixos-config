{lib, ...}: let
  common = import ../../common.nix;
in {
  networking = {
    hostName = "sgnixos";
    networkmanager.enable = true;
    nameservers = [
      common.network.primaryDNS
      "4.2.2.1"
    ];
    enableIPv6 = true;
    hosts = {
      "127.0.0.1" = ["localhost"];
      "172.20.26.201" = ["sgnixos"];
    };
    proxy.default = "http://127.0.0.1:1080";
    proxy.noProxy = lib.concatStringsSep "," [
      "127.0.0.1"
      "localhost"
      common.network.proxyHost
    ];
    firewall = {
      enable = true;
      allowedTCPPorts = [
        2049
        53317 # LocalSend
      ];
      allowedUDPPorts = [
        53317 # LocalSend 局域网设备自动发现
      ];
    };
  };

  # 启用 KDE Connect 支持并自动开放防火墙端口 (1714-1764 TCP/UDP) 与 DBus 权限
  programs.kdeconnect.enable = true;
}
