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
      url = "path:/home/sgnay/0todo/sgnur-packages";
      inputs.nixpkgs.follows = "nixpkgs";
    };

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
    inputs =
      rawInputs
      // {
        inherit (apps) fcitx5-vinput kache omp rustconn ferrite goose simple-translation;
      };

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
    in
      # 应用类包（omp/goose/kache/...）由 ./apps 子 flake 的 overlay 提供
      (inputs.apps.overlays.default final prev)
      // {
        inherit
          (myPkgs)
          univpn
          sunloginclient
          oxideterm
          velotype
          deepseek-reasonix
          simple-ocr
          ;
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
