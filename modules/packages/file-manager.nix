{ pkgs, ... }: {
  programs.nautilus-open-any-terminal = {
    enable = true;
    terminal = "ghostty";
  };
  services.gvfs.enable = true;
  # services.udisks2.enable = true;
  # services.devmon.enable = true;
}
