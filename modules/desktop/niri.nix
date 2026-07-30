{pkgs, ...}: {
  programs.niri.enable = true;

  # 使用 Thunar 替代 Nautilus 作为文件选择器
  programs.niri.useNautilus = false;

  # 启用 XWayland 以支持 X11 应用（如 WPS Office）
  programs.xwayland.enable = true;

  environment.systemPackages = with pkgs; [
    dms-shell
    # niri 相关工具
    xdg-desktop-portal-gtk

    # XWayland 支持（niri 使用 xwayland-satellite 自动管理 X11 应用）
    xwayland-satellite
  ];
}
