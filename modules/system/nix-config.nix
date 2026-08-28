{...}: {
  nix.settings = {
    experimental-features = ["nix-command" "flakes"];
    trusted-users = ["root" "@wheel"];

    substituters = [
      "https://mirrors.ustc.edu.cn/nix-channels/store"
      "https://mirrors.sjtug.sjtu.edu.cn/nix-channels/store"
      "https://cache.nixos.org"
    ];

    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    ];

    # 显式信任所有 substituters，确保一个返回 404 时自动回退到下一个
    trusted-substituters = [
      "https://mirrors.ustc.edu.cn/nix-channels/store"
      "https://mirrors.sjtug.sjtu.edu.cn/nix-channels/store"
      "https://cache.nixos.org"
    ];

    # 并行下载/编译
    max-jobs = "auto";
    cores = 0;

    # 找不到缓存时不中止，继续尝试后续 substituter
    fallback = true;
  };

  nixpkgs.config.allowUnfree = true;

  # 自动垃圾回收：每周执行，删除 14 天前的旧代次
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  # 自动优化 store（硬链接重复文件）
  nix.settings.auto-optimise-store = true;

  # 自动全量 store 优化（每天凌晨 3 点执行 nix store optimise）
  nix.optimise = {
    automatic = true;
    dates = ["03:00"];
  };
}
