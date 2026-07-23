# modules/packages/default.nix — 系统软件包集中管理
# 纯包列表集中于此，涉及额外配置的模块（file-manager、input、thunar-themes、tolaria、virtualization）保留各自文件
{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    zed-editor
    picocom
    minicom
    screen
    putty
  ];
}
