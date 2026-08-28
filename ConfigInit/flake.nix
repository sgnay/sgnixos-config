{
  description = "A custom NixOS flake for sgnay";

  inputs = {
    # ============ 包源 ============
    # NixOS 官方软件源 - 稳定版 (nixos-26.05)
    # nixpkgs.url = "github:NixOS/nixpkgs/nixos-26.05";
    nixpkgs.url = "https://mirrors.ustc.edu.cn/nix-channels/nixos-26.05/nixexprs.tar.xz";

    # ============ 硬件支持 ============
    # NixOS 硬件兼容配置
    nixos-hardware.url = "github:NixOS/nixos-hardware";

    # ============ 开发工具 ============
    # VSCode Server - 远程开发支持
    vscode-server = {
      url = "github:nix-community/nixos-vscode-server";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = {
    self,
    nixpkgs,
    nixos-hardware,
    vscode-server,
    ...
  } @ inputs: {
    nixosConfigurations.sgnixos = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        ./configuration.nix
        vscode-server.nixosModules.default
        nixos-hardware.nixosModules.common-cpu-amd
        ({
          config,
          pkgs,
          ...
        }: {
          services.vscode-server.enable = true;
          programs.nix-ld.enable = true;
        })
      ];
      specialArgs = {inherit inputs;};
    };
  };
}
