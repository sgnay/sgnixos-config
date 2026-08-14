{
  description = "A custom NixOS flake for sgnay";

  inputs = {
    myRepo = {
      url = "github:sgnay/sgnur-packages";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # ============ 包源 ============
    # NixOS 官方软件源 - 稳定版 (nixos-26.05)
    nixpkgs.url = "nixpkgs/nixos-26.05";
    # community NUR
    flake-utils.url = "github:numtide/flake-utils";
    nur = {
      url = "github:nix-community/NUR";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # 配置 unstable 源地址
    nixpkgs-unstable.url = "nixpkgs/nixos-unstable";
    # 语音输入法
    fcitx5-vinput = {
      url = "github:xifan2333/fcitx5-vinput";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # ============ 硬件支持 ============
    # NixOS 硬件兼容配置
    nixos-hardware.url = "github:NixOS/nixos-hardware";

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

    # ============ Home Manager ============
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  nixConfig = {
    extra-substituters = ["https://fcitx5-vinput.cachix.org"];
    extra-trusted-public-keys = [
      "fcitx5-vinput.cachix.org-1:XpX3AA6+dDIX4qJhb1QM7sbTwX6/qSlGvW8Z5NK6XdU="
    ];
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    nixos-hardware,
    vscode-server,
    home-manager,
    pre-commit-hooks,
    nur,
    ...
  }: let
    unstable = import inputs.nixpkgs-unstable {
      system = "x86_64-linux";
      config.allowUnfree = true;
    };
  in {
    nixosConfigurations.sgnixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        inputs.sops-nix.nixosModules.sops
        {
          nixpkgs.overlays = [
            (_final: prev: let
              myPkgs = inputs.myRepo.packages."${prev.stdenv.hostPlatform.system}";
            in {
              univpn = myPkgs.univpn;
              sunloginclient = myPkgs.sunloginclient;
              omp = myPkgs.omp;
              rustconn = myPkgs.rustconn;
              oxideterm = myPkgs.oxideterm;
              velotype = myPkgs.velotype;
              goose = myPkgs.goose;
              goose-desktop = myPkgs.goose-desktop;
              deepseek-reasonix = myPkgs.deepseek-reasonix;
              simple-translation = myPkgs.simple-translation;
              fcitx5-vinput = inputs.fcitx5-vinput.packages."${prev.stdenv.hostPlatform.system}".default;
            })
          ];
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
          home-manager.extraSpecialArgs = {inherit inputs unstable;};
        })
      ];
      specialArgs = {inherit inputs unstable;};
    };

    homeConfigurations = {
      sgnay = inputs.home-manager.lib.homeManagerConfiguration {
        pkgs = import nixpkgs {
          system = "x86_64-linux";
          config.allowUnfree = true;
          overlays = [nur.overlays.default];
        };
        modules = [./home/home.nix];
        extraSpecialArgs = {inherit inputs unstable;};
      };
    };

    # Pre-commit checks
    checks.x86_64-linux.pre-commit-check = pre-commit-hooks.lib.x86_64-linux.run {
      src = ./.;
      hooks = {
        alejandra.enable = true;
        statix.enable = true;
        deadnix.enable = true;
        deadnix.settings.noLambdaPatternNames = true;
      };
    };

    devShells.x86_64-linux.default = nixpkgs.legacyPackages.x86_64-linux.mkShell {
      inherit (self.checks.x86_64-linux.pre-commit-check) shellHook;
      buildInputs = self.checks.x86_64-linux.pre-commit-check.enabledPackages;
    };
  };
}
