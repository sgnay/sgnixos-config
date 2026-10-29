{
  description = "A custom NixOS flake for sgnay";

  inputs = {
    # ============ 包源 ============
    # NixOS 官方软件源 - 稳定版 (nixos-26.05)
    nixpkgs.url = "nixpkgs/nixos-26.05";
    # community NUR
    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # 配置 unstable 源地址
    nixpkgs-unstable.url = "nixpkgs/nixos-unstable";
    # ============ 硬件支持 ============
    # NixOS 硬件兼容配置
    nixos-hardware.url = "github:NixOS/nixos-hardware";

    # ============ 应用集合 ============
    # 应用类 flake（omp/goose/kache/...）统一收拢到 ./apps 子 flake，
    # 主 flake 保持稳定：应用的增删与更新只改 apps/flake.nix
    apps = {
      url = "path:./apps";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # ============ 开发工具 ============
    # VSCode Server - 远程开发支持
    vscode-server.url = "github:nix-community/nixos-vscode-server";
    # SOPS-Nix - 密钥加解密管理
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Pre-commit hooks
    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # custom nur repo
    myRepo = {
      #  url = "path:/home/sgnay/0todo/sgnur-packages";
      url = "github:sgnay/sgnur-packages";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Nix packages for AI coding agents and development tools.
    # 不 follows 主 nixpkgs：上游包依赖 nixpkgs-unstable 新增的构建钩子
    # （installAgentSkills、wrapBuddy 等），26.05 稳定源中不存在。
    llm-agents.url = "github:numtide/llm-agents.nix";
    # DSH（DeepSeek Harness）桌面端打包；同样跟踪 nixpkgs-unstable（需要 pnpm_11 ≥ 11.22），
    # 故不 follows 主 nixpkgs。
    deepseek-harness.url = "github:Moraxyc/deepseek-harness.nix";
    # ============ Home Manager ============
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  nixConfig = {
    extra-substituters = [
      # fcitx5-vinput（apps 子 flake）的二进制缓存
      "https://fcitx5-vinput.cachix.org"
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "fcitx5-vinput.cachix.org-1:XpX3AA6+dDIX4qJhb1QM7sbTwX6/qSlGvW8Z5NK6XdU="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  outputs = rawInputs @ {
    self,
    nixpkgs,
    nixos-hardware,
    vscode-server,
    home-manager,
    pre-commit-hooks,
    apps,
    ...
  }: let
    system = "x86_64-linux"; # 统一定义系统架构标识符
    common = import ./common.nix;

    # 应用类 input 已迁至 ./apps 子 flake，这里按原名透传回 inputs，
    # 模块中的 inputs.omp / inputs.kache / inputs.ferrite 等引用无需改动
    inputs = rawInputs // apps.appFlakes;

    unstable = import inputs.nixpkgs-unstable {
      inherit system;
      config.allowUnfree = true;
    };

    specialArgs = {
      inherit inputs unstable common;
    };

    customOverlay = final: prev: let
      targetSystem = prev.stdenv.hostPlatform.system;
      myPkgs = inputs.myRepo.packages.${targetSystem};
      llmAgents = inputs.llm-agents.packages.${targetSystem};
      dshPkgs = inputs.deepseek-harness.packages.${targetSystem};
    in
      # 应用类包（omp/goose/kache/...）由 ./apps 子 flake 的 overlay 提供
      (inputs.apps.overlays.default final prev)
      // {
        inherit
          (myPkgs)
          univpn
          sunloginclient
          velotype
          fcitx5-windinput
          ;
        # AI 编码代理统一取自 llm-agents.nix：
        # opencode2      = OpenCode 2（上游二进制名 opencode，此处以 opencode2 安装）
        # qoder-cli      = Qoder AI CLI（unfree），命令 qodercli
        # dsh            = DeepSeek Harness CLI
        # freebuff       = Freebuff 编码代理
        # cline          = Cline 编码代理
        # codebuddy-code = 腾讯 CodeBuddy，命令 codebuddy
        inherit
          (llmAgents)
          opencode2
          qoder-cli
          dsh
          freebuff
          cline
          codebuddy-code
          ;
        # DSH 桌面端取自 deepseek-harness.nix：用官方变体（自带 primary-runtime 载荷），
        # unofficial 变体缺 resources/runtime/<arch>/primary-runtime，启动即失败。
        # 两者都提供 bin/dsh-desktop，只能二选一。
        inherit (dshPkgs) dsh-desktop-official;
        luafilesystem = prev.luaPackages.luafilesystem;
      };
  in {
    overlays.default = customOverlay;

    nixosConfigurations.sgnixos = nixpkgs.lib.nixosSystem {
      inherit system specialArgs;
      modules = [
        inputs.sops-nix.nixosModules.sops
        {
          nixpkgs.overlays = [customOverlay];
        }
        ./configuration.nix
        vscode-server.nixosModules.default
        nixos-hardware.nixosModules.common-cpu-amd
        home-manager.nixosModules.home-manager
        (_: {
          services.vscode-server.enable = true;
          programs.nix-ld.enable = true;
          home-manager.useGlobalPkgs = true;
          home-manager.backupFileExtension = "backup";
          home-manager.users.sgnay = import ./home/home.nix;
          home-manager.extraSpecialArgs = specialArgs;
        })
      ];
    };

    homeConfigurations = {
      sgnay = inputs.home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
          overlays = [customOverlay];
        };
        modules = [./home/home.nix];
        extraSpecialArgs = specialArgs;
      };
    };

    # Pre-commit checks
    checks.${system}.pre-commit-check = pre-commit-hooks.lib.${system}.run {
      src = ./.;
      hooks = {
        alejandra.enable = true;
        statix.enable = true;
        deadnix.enable = true;
        deadnix.settings.noLambdaPatternNames = true;
      };
    };

    devShells.${system}.default = let
      check = self.checks.${system}.pre-commit-check;
    in
      nixpkgs.legacyPackages.${system}.mkShell {
        inherit (check) shellHook;
        buildInputs = check.enabledPackages;
      };
  };
}
