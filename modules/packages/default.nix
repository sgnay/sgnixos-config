# modules/packages/default.nix — 系统级软件包集中管理
# 所有系统级包（environment.systemPackages）统一在此声明，按功能分类
# 字体包由 modules/desktop/fonts.nix 中的 fonts.packages 管理
# 自定义打包（symlinkJoin 等）在 wrapped.nix 中
{pkgs, ...}: {
  environment.systemPackages = with pkgs; [
    # ========== 系统基础工具 ==========
    neovim
    unzip
    curl
    file
    gcc # C 编译器（Mason 等工具依赖）
    tree
    e2fsprogs
    bc

    # ========== Nix 开发工具 ==========
    nil # Nix LSP
    nixfmt # Nix 格式化（RFC-style）
    statix # Nix 代码检查

    # ========== 虚拟化 ==========
    podman-compose
    buildah
    skopeo
    virt-viewer
    spice
    spice-gtk

    # ========== 网络存储 ==========
    nfs-utils # NFS 客户端/服务端工具
    samba # SMB/CIFS 服务端
    cifs-utils # mount -t cifs 支持
  ];
}
