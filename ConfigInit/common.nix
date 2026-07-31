{
  # NixOS 和 Home Manager 版本号
  version = "26.05";

  # 网络配置变量
  network = {
    primaryDNS = "172.20.26.100";
    proxyHost = "172.20.26.100";
    proxyPort = 1080;
  };
}
