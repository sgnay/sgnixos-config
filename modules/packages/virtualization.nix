{ config, pkgs, ... }:
{
  # Podman 容器
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    defaultNetwork.settings.dns_enabled = true;
  };

  # Libvirt 虚拟机管理
  virtualisation.libvirtd = {
    enable = true;
  };

  programs.virt-manager.enable = true;

  # 将用户加入所需组
  users.groups.libvirtd.members = let
    secrets = import ../../secrets.nix;
  in [ secrets.username ];

  users.groups.podman.members = let
    secrets = import ../../secrets.nix;
  in [ secrets.username ];
}
