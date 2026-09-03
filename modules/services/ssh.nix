{common, ...}: let
  userName = common.username;
in {
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
      AllowUsers = [userName];
    };
    openFirewall = true;
  };
}
