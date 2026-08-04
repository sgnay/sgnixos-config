# modules/services/printing.nix — CUPS 打印服务、打印机驱动与 SANE 扫描仪支持
{ pkgs, ... }:
let
  common = import ../../common.nix;
in
{
  # 开启 CUPS 打印服务并配置常用品牌打印机驱动
  services.printing = {
    enable = true;
    drivers = with pkgs; [
      gutenprint                   # 常见喷墨/激光打印机驱动 (Epson, Canon, HP 等)
      hplip                        # 惠普 (HP) 打印机与多功能一体机驱动
      brlaser                      # 兄弟 (Brother) 激光打印机开源驱动
      splix                        # 三星 (Samsung) SPL 激光打印机驱动
      samsung-unified-linux-driver  # 三星 (Samsung) 官方统一打印驱动
    ];
  };

  # 开启无驱动 USB 打印与扫描 (IPP-over-USB)
  services.ipp-usb.enable = true;

  # 开启 Avahi (mDNS/Bonjour) 服务，自动发现局域网无线/网络打印机
  services.avahi = {
    enable = true;
    nssmdns4 = true;
    openFirewall = true;
  };

  # 开启 SANE 扫描仪服务支持 (用于多功能一体机扫描)
  hardware.sane = {
    enable = true;
    extraBackends = with pkgs; [
      sane-airscan # 网络与无驱动 (eSCL / WSD) 协议扫描支持
    ];
  };

  # 系统内置打印管理与扫描 GUI 工具
  environment.systemPackages = with pkgs; [
    cups
    system-config-printer # GTK 打印机配置与管理工具
    simple-scan           # 极简 GUI 扫描工具
  ];

  # 将主用户添加至打印 (lp) 与扫描 (scanner) 系统权限组
  users.groups.scanner.members = [ common.username ];
  users.groups.lp.members = [ common.username ];
}
