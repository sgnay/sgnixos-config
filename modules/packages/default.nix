# modules/packages/default.nix — 系统软件包集中管理
{ pkgs, ... }: {
  environment.systemPackages = with pkgs; [
    picocom
    minicom
    screen
    putty
    e2fsprogs
    # 安装 Orbitron 字体到系统（供 GTK CSS 引用）
    orbitron
  ];
}
