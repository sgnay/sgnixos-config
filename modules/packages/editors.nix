{ config, pkgs, ... }:
{
  # VSCode 由 Home Manager 管理（包括包安装和配置）
  # 如需其他编辑器可在此添加

  environment.systemPackages = with pkgs; [
    zed-editor
    lapce
    helix
  ];
}
