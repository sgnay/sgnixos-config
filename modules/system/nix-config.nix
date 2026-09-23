{...}: {
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    trusted-users = [
      "root"
      "@wheel"
    ];

    substituters = [
      "https://mirrors.cernet.edu.cn/nix-channels/store"
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

    # 限制同时编译的软件包数量（建议 2 ~ 4，内存小建议 1 或 2）
    max-jobs = 4;

    # 限制单个软件包编译时的 CPU 核心数（0 表示使用全部可用核心）
    cores = 4;

    # 找不到缓存时不中止，继续尝试后续 substituter
    fallback = true;

    # 自动优化 store（硬链接重复文件）
    auto-optimise-store = true;
  };

  systemd.services.nix-daemon = {
    serviceConfig = {
      # 内存自适应：
      # 占用达总内存 75% 时触发内核积极回收和节流
      # 16G 机器自动算为 12G，32G 机器自动算为 24G，64G 机器自动算为 48G
      MemoryHigh = "75%";
      # 超过 85% 时终止过度消耗内存的单个构建任务，永远为桌面和前台保留 15% 内存
      MemoryMax = "85%";

      # 优先级降级：保证构建时即使 CPU 满载，鼠标、桌面、浏览器依然丝滑不卡顿
      Nice = 19; # 最低 CPU 调度优先级
      CPUWeight = 20; # 降低 CPU 争抢权重（默认 100）
      IOWeight = 20; # 降低磁盘 I/O 争抢权重（默认 100）
    };
    environment = {
      TMPDIR = "/var/tmp";
    };
  };

  nixpkgs.config.allowUnfree = true;

  # 自动垃圾回收：每周执行，删除 14 天前的旧代次
  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 14d";
  };

  # 自动全量 store 优化（每天凌晨 3 点执行 nix store optimise）
  nix.optimise = {
    automatic = true;
    dates = ["03:00"];
  };
}
