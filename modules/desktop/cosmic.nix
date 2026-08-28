# modules/desktop/cosmic.nix — COSMIC 桌面环境（System76 Rust 原生 DE）
# 第二桌面选项，登录时在 greetd 中选择 niri-session 或 start-cosmic
{pkgs, ...}: {
  # === COSMIC 桌面环境 ===
  services.desktopManager.cosmic.enable = true;

  # 排除不需要的 COSMIC 自帶应用
  # 注意：cosmic-files 是 corePkgs（排除会导致 COSMIC 崩溃），必须保留
  environment.cosmic.excludePackages = with pkgs; [
    cosmic-store # 不需要 Flatpak 商店
    cosmic-player # 已有 vlc/mpv
    cosmic-term # 使用 wezterm/ghostty
    cosmic-edit # 使用 neovim
    networkmanagerapplet # 不需要
  ];

  # 将 COSMIC 会话加入 greetd 会话列表
  services.displayManager.sessionPackages = [pkgs.cosmic-session];
}
