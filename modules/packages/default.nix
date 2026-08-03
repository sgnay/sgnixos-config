# modules/packages/default.nix — 系统软件包集中管理
{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    zed-editor
    picocom
    minicom
    screen
    putty
    e2fsprogs
  ];
}
