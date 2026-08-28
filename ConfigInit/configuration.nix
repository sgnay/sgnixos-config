# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).
{
  config,
  pkgs,
  ...
}: let
  # 从本地文件导入敏感数据
  secrets = import ./secrets.nix;
  common = import ./common.nix;
  userName = secrets.username;
in {
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  # Bootloader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostName = "sgnixos"; # Define your hostname.
  # 启用 Flakes 特性以及配套的 nix 命令行工具
  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];

    # 二进制缓存
    substituters = [
      "https://mirrors.tuna.tsinghua.edu.cn/nix-channels/store"
      "https://mirror.sjtu.edu.cn/nix-channels/store"
      "https://mirrors.ustc.edu.cn/nix-channels/store"
      "https://cache.nixos.org"
    ];

    trusted-public-keys = [
      "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
    ];
  };
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure logind
  services.logind.settings.Login.HandlePowerKey = "ignore"; # Triggered when the power key/button is pressed.
  services.logind.settings.Login.HandleSuspendKey = "ignore";
  services.logind.settings.Login.HandleHibernateKey = "ignore";
  services.logind.settings.Login.HandleLidSwitch = "suspend"; # Triggered when the lid is closed, except in the cases below.
  services.logind.settings.Login.HandleLidSwitchDocked = "ignore"; # Triggered when the lid is closed if the system is inserted in a docking station, or more than one display is connected.
  services.logind.settings.Login.HandleLidSwitchExternalPower = "ignore"; # Triggered when the lid is closed if the system is connected to external power.

  # 网络代理配置（来自 common.nix）
  networking.proxy.default = "http://${common.network.proxyHost}:${builtins.toString common.network.proxyPort}";
  networking.proxy.noProxy = "127.0.0.1,localhost,${common.network.proxyHost}";

  # Enable networking
  networking = {
    networkmanager.enable = true;
    nameservers = [
      common.network.primaryDNS
      "4.2.2.1"
    ];
    enableIPv6 = false;
    hosts = {
      "127.0.0.1" = ["localhost"];
      "172.20.26.201" = ["sgnixos"];
    };
  };

  # Set your time zone.
  time.timeZone = "Asia/Shanghai";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_US.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "zh_CN.UTF-8";
    LC_IDENTIFICATION = "zh_CN.UTF-8";
    LC_MEASUREMENT = "zh_CN.UTF-8";
    LC_MONETARY = "zh_CN.UTF-8";
    LC_NAME = "zh_CN.UTF-8";
    LC_NUMERIC = "zh_CN.UTF-8";
    LC_PAPER = "zh_CN.UTF-8";
    LC_TELEPHONE = "zh_CN.UTF-8";
    LC_TIME = "zh_CN.UTF-8";
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.${userName} = {
    isNormalUser = true;
    description = userName;
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
    openssh.authorizedKeys.keys = secrets.user-public-ssh-keys;
    packages = with pkgs; [
      uv
      nodejs
      wget
      aria2
    ];
  };

  # sudo 配置：仅特定命令免密，其他 sudo 仍需密码
  security.sudo = {
    enable = true;
    extraRules = [
      {
        groups = ["wheel"];
        commands = [
          # nixos-rebuild 及其内部调用的 nix 命令
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

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  environment.systemPackages = with pkgs; [
    neovim
    git
    unzip
    curl
  ];

  environment.variables.EDITOR = "nvim";
  environment.variables.VISUAL = "nvim";

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no"; # disable root login
      PasswordAuthentication = false; # disable password login
      AllowUsers = [userName];
    };
    openFirewall = true;
  };

  # Open ports in the firewall.
  networking.firewall.allowedTCPPorts = [
    9090
    80
  ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  networking.firewall.enable = true;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "26.05"; # Did you read the comment?
}
