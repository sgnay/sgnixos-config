{
  lib,
  pkgs,
  ...
}:
{
  boot = {
    loader = {
      systemd-boot.enable = true;
      systemd-boot.configurationLimit = 5;
      efi.canTouchEfiVariables = true;
      # 自动清理旧的引导项
      systemd-boot.graceful = true;
    };
    # 默认使用 Zen 内核（响应更快，适合桌面使用）
    kernelPackages = pkgs.linuxPackages_zen;
    # Plymouth 开机动画 — 隐藏启动日志，显示品牌 Logo
    plymouth.enable = true;
    # bgrt（默认）从 UEFI BGRT 表读取 OEM Logo（HP），效果类似 CentOS
    # 可选其他主题：spinner, breeze, catppuccin-mocha, text 等
    plymouth.theme = lib.mkDefault "breeze";
    # 关闭控制台日志输出，防止日志从 Plymouth 背后泄漏
    consoleLogLevel = 0;
    # 与 Plymouth 的 "splash" 配合，进一步压制内核消息
    kernelParams = [ "quiet" ];
  };

  # 主线稳定内核 — 作为 specialisation 保留备选
  specialisation.stable-kernel = {
    configuration = {
      boot.kernelPackages = lib.mkForce pkgs.linuxPackages;
    };
  };
}
