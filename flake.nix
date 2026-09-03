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
    # oh-my-pi, AI Coding agent
    omp = {
      url = "github:can1357/oh-my-pi/v18.0.10";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # RustConn, connection manager
    rustconn = {
      url = "github:totoshko88/RustConn";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # Ferrite, text editor for Markdown
    ferrite = {
      url = "github:OlaProeis/Ferrite";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # custom nur repo
    myRepo = {
      url = "github:sgnay/sgnur-packages";
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
      "https://fcitx5-vinput.cachix.org"
      "https://nix-community.cachix.org"
    ];
    extra-trusted-public-keys = [
      "fcitx5-vinput.cachix.org-1:XpX3AA6+dDIX4qJhb1QM7sbTwX6/qSlGvW8Z5NK6XdU="
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
    ];
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      nixos-hardware,
      vscode-server,
      home-manager,
      pre-commit-hooks,
      ...
    }:
    let
      system = "x86_64-linux"; # 统一定义系统架构标识符
      common = import ./common.nix;

      unstable = import inputs.nixpkgs-unstable {
        inherit system;
        config.allowUnfree = true;
      };

      specialArgs = {
        inherit inputs unstable common;
      };

      customOverlay =
        _final: prev:
        let
          targetSystem = prev.stdenv.hostPlatform.system;
          getDefault = flake: flake.packages.${targetSystem}.default;
          myPkgs = inputs.myRepo.packages.${targetSystem};
        in
        {
          inherit (myPkgs)
            univpn
            sunloginclient
            oxideterm
            nyaterm
            velotype
            goose
            goose-desktop
            deepseek-reasonix
            simple-translation
            simple-ocr
            ;
          fcitx5-vinput = getDefault inputs.fcitx5-vinput;
          omp = (getDefault inputs.omp).overrideAttrs (_oldAttrs: {
            __noSandbox = true;
          });
          rustconn = getDefault inputs.rustconn;
          ferrite = getDefault inputs.ferrite;
        };
    in
    {
      overlays.default = customOverlay;

      nixosConfigurations.sgnixos = nixpkgs.lib.nixosSystem {
        inherit system specialArgs;
        modules = [
          inputs.sops-nix.nixosModules.sops
          {
            nixpkgs.overlays = [ customOverlay ];
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
            overlays = [ customOverlay ];
          };
          modules = [ ./home/home.nix ];
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

      devShells.${system}.default =
        let
          check = self.checks.${system}.pre-commit-check;
        in
        nixpkgs.legacyPackages.${system}.mkShell {
          inherit (check) shellHook;
          buildInputs = check.enabledPackages;
        };
    };
}
