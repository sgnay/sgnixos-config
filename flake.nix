{
  description = "A custom NixOS flake for sgnay";

  inputs = {
    myRepo = {
      url = "github:sgnay/sgnur-packages"; # 发布用
      # url = "path:/home/sgnay/agents/sgnur-packages"; # 本地开发
      inputs.nixpkgs.follows = "nixpkgs";
    };
    # ============ 包源 ============
    # NixOS 官方软件源 - 稳定版 (nixos-26.05)
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";

    # ============ 硬件支持 ============
    # NixOS 硬件兼容配置
    nixos-hardware.url = "github:NixOS/nixos-hardware";

    # ============ 开发工具 ============
    # VSCode Server - 远程开发支持
    vscode-server = {
      url = "github:nix-community/nixos-vscode-server";
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

    # ============ 敏感数据（不跟踪 Git）============
    # 修改后需 --update-input secrets 使新内容生效
    secrets-file = {
      url = "path:/etc/nixos/secrets.nix";
      flake = false;
    };
  };

  outputs = inputs @ {
    self,
    nixpkgs,
    nixos-hardware,
    vscode-server,
    home-manager,
    secrets-file,
    pre-commit-hooks,
    ...
  }: let
    # 从 flake input（path）导入 secrets 内容
    secrets = import secrets-file;
  in {
    nixosConfigurations.sgnixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        {
          nixpkgs.overlays = [
            (_final: prev: {
              univpn = inputs.myRepo.packages."${prev.stdenv.hostPlatform.system}".univpn;
              nyaterm = inputs.myRepo.packages."${prev.stdenv.hostPlatform.system}".nyaterm;
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
          home-manager.extraSpecialArgs = {inherit inputs secrets;};
        })
      ];
      specialArgs = {inherit inputs secrets;};
    };

    homeConfigurations = {
      sgnay = inputs.home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        modules = [./home/home.nix];
        extraSpecialArgs = {inherit inputs secrets;};
      };
    };

    # Pre-commit checks
    checks.x86_64-linux.pre-commit-check = pre-commit-hooks.lib.x86_64-linux.run {
      src = ./.;
      hooks = {
        alejandra.enable = true;
        statix.enable = true;
        deadnix.enable = true;
      };
    };

    devShells.x86_64-linux.default = nixpkgs.legacyPackages.x86_64-linux.mkShell {
      inherit (self.checks.x86_64-linux.pre-commit-check) shellHook;
      buildInputs = self.checks.x86_64-linux.pre-commit-check.enabledPackages;
    };
  };
}
