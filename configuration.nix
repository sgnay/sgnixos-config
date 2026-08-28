# configuration.nix — 最小化主配置，仅 imports 各模块
{ pkgs, ... }: {
  imports = [
    ./hardware-configuration.nix

    # 系统基础模块
    ./modules/system/boot.nix
    ./modules/system/locale.nix
    ./modules/system/network.nix
    ./modules/system/users.nix
    ./modules/system/nix-config.nix
    ./modules/system/base.nix

    # 服务
    ./modules/services/ssh.nix
    ./modules/services/greetd.nix
    ./modules/services/xray.nix

    # 桌面环境
    ./modules/desktop/niri.nix
    ./modules/desktop/cosmic.nix
    ./modules/desktop/fonts.nix
    ./modules/desktop/audio.nix

    # 软件包
    ./modules/packages # browsers, terminals, office, communication, editors, multimedia
    ./modules/packages/file-manager.nix
    ./modules/packages/input.nix
    ./modules/packages/virtualization.nix

    # 网络存储服务
    ./modules/services/network-storage.nix

    # UniVPN 客户端
    ./modules/services/univpn.nix

    # 向日葵远程控制客户端
    ./modules/services/sunloginclient.nix

    # 打印机与扫描仪服务
    ./modules/services/printing.nix
  ];

  # FSTRIM 定时清理 (优化 SSD/NVMe 寿命与性能)
  services.fstrim = {
    enable = true;
    interval = "weekly";
  };
}
