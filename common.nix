{
  # NixOS 和 Home Manager 版本号
  version = "26.05";

  # 用户名和敏感数据的公共部分
  username = "sgnay";
  email = "sgnay@outlook.com";
  user-public-ssh-keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIHXAUgplK6BSy6laSuY4A536eXxjDSYJfqR0hCEwk8Tg sgnay@sgendeavour"
  ];

  # 网络配置变量
  network = {
    primaryDNS = "172.20.26.100";
    proxyHost = "172.20.26.100";
    proxyPort = 1080;
  };
}
