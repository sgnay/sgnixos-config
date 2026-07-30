{pkgs, ...}: let
  common = import ../../common.nix;
  userName = common.username;
in {
  programs.fish.enable = true;

  users.users.${userName} = {
    isNormalUser = true;
    description = userName;
    shell = pkgs.fish;
    extraGroups = ["networkmanager" "wheel"];
    openssh.authorizedKeys.keys = common.user-public-ssh-keys;
    packages = with pkgs; [
      uv
      nodejs
      wget
      aria2
    ];
  };

  security.sudo = {
    enable = true;
    extraConfig = ''
      Defaults pwfeedback
      Defaults passprompt="使用 sudo 需要 %p 的密码: "
    '';
    extraRules = [
      {
        groups = ["wheel"];
        commands = [
          {
            command = "/run/current-system/sw/bin/nixos-rebuild";
            options = ["NOPASSWD"];
          }
          {
            command = "/run/current-system/sw/bin/nix";
            options = ["NOPASSWD"];
          }
          {
            command = "/run/current-system/sw/bin/nix-collect-garbage";
            options = ["NOPASSWD"];
          }
        ];
      }
    ];
  };
}
