# modules/packages/communication.nix — 即时通讯软件
{ config, pkgs, ... }:
{
  environment.systemPackages = with pkgs; [
    wechat-uos        # 微信
    qq                # QQ
    wemeet            # 腾讯会议
    telegram-desktop  # Telegram 即时通讯
    localsend         # 局域网文件传输（跨平台 AirDrop）
  ];
}
