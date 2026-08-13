{pkgs, ...}: let
  common = import ../../common.nix;
in {
  # Podman 容器支持与 Docker 兼容性配置
  virtualisation.podman = {
    enable = true;
    dockerCompat = true;
    dockerSocket.enable = true;
    defaultNetwork.settings.dns_enabled = true;
  };

  # Libvirt 虚拟机管理与 QEMU/KVM 硬件加速与 TPM 支持
  virtualisation.libvirtd = {
    enable = true;
    qemu = {
      package = pkgs.qemu_kvm;
      runAsRoot = true;
      swtpm.enable = true;
    };
  };

  # GUI 虚拟机管理工具
  programs.virt-manager.enable = true;

  # 将用户加入 libvirtd 与 podman 管理组
  users.groups.libvirtd.members = [common.username];
  users.groups.podman.members = [common.username];
}
