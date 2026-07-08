# configuration.nix — 最小化主配置，仅 imports 各模块
{
  config,
  pkgs,
  lib,
  ...
}:
{
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
    ./modules/packages/browsers.nix
    ./modules/packages/terminals.nix
    ./modules/packages/office.nix
    ./modules/packages/file-manager.nix
    ./modules/packages/input.nix
    ./modules/packages/virtualization.nix
    ./modules/packages/communication.nix
    ./modules/packages/multimedia.nix
    ./modules/packages/editors.nix
    ./modules/packages/thunar-themes.nix
    ./modules/packages/tolaria.nix

    # 网络存储服务
    ./modules/services/network-storage.nix

    # UniVPN 客户端
    ./modules/services/univpn.nix
  ];
}
