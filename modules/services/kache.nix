# modules/services/kache.nix — Kache 编译缓存 (Rust/C/C++ 加速)
# 上游 flake: github:kunobi-ninja/kache (stable 分支, nixpkgs follow)
# 提供:
#   - pkgs.kache (经 overlay, 用上游 rust-toolchain.toml 固定的工具链构建)
#   - RUSTC_WRAPPER 系统环境变量 (services.kache.rustcWrapper, 默认 true)
#   - /etc/kache/config.toml (services.kache.settings)
#   - 可选后台 daemon (systemd user service)
{
  inputs,
  ...
}: {
  imports = [inputs.kache.nixosModules.kache];
  services.kache = {
    enable = true;
    daemon.enable = true;
    settings.cache = {
      # 本地缓存上限, 超出后 GC
      local_max_size = "50GB";
    };
  };
}
