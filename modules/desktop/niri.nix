{pkgs, ...}: {
  programs.niri.enable = true;
  # 如果使用其它文件管理器替代 Nautilus，设置为 false
  programs.niri.useNautilus = true;
  # 启用 XWayland 以支持 X11 应用（如 WPS Office）
  programs.xwayland.enable = true;
}
