{
  description = "A custom NixOS flake for sgnay";

  inputs = {
    # ============ 包源 ============
    # NixOS 官方软件源 - 稳定版 (nixos-26.05)
    # nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
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

    # ============ Home Manager ============
    home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # ============ 敏感数据（不跟踪 Git，通过 path input 引入）============
    secrets = {
      url = "path:/etc/nixos/secrets.nix";
      flake = false;
    };

    # ============ UniVPN 安装包（29MB 二进制，不跟踪 Git）============
    univpn-zip = {
      url = "path:/etc/nixos/pkgs/univpn-linux-64-10781.19.0.1214.zip";
      flake = false;
    };

  };

  outputs = { self, nixpkgs, nixos-hardware, vscode-server, home-manager, secrets, univpn-zip, ... }@inputs: {
    nixosConfigurations.sgnixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./configuration.nix
        vscode-server.nixosModules.default
        nixos-hardware.nixosModules.common-cpu-amd
        home-manager.nixosModules.home-manager
        ({ config, pkgs, ... }: {
          services.vscode-server.enable = true;
          programs.nix-ld.enable = true;
          home-manager.useGlobalPkgs = true;
          home-manager.backupFileExtension = "backup";
          home-manager.users.sgnay = import ./home/home.nix;
          home-manager.extraSpecialArgs = { inherit inputs; secrets = import secrets; };
        })
      ];
      specialArgs = { inherit inputs; secrets = import secrets; univpn-zip = univpn-zip; };
    };

    homeConfigurations = {
      sgnay = inputs.home-manager.lib.homeManagerConfiguration {
        pkgs = nixpkgs.legacyPackages.x86_64-linux;
        modules = [ ./home/home.nix ];
        extraSpecialArgs = { inherit inputs; secrets = import secrets; };
      };
    };
  };
}
