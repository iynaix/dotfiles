{
  user,
  pkgs,
  lib,
  config,
  isNixOS,
  ...
}: {
  imports = [
    ./hyprland
    ./programs
    ./shell
  ];

  # mounting and unmounting of disks
  services.udiskie = {
    enable = true;
    automount = true;
    notify = true;
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  # setup fonts for other distros, run "fc-cache -f" to refresh fonts
  fonts.fontconfig.enable = !isNixOS;

  home = {
    username = user;
    homeDirectory = "/home/${user}";
    # do not change this value
    stateVersion = "22.11";

    packages = with pkgs;
      [
        curl
        exa
        gzip
        killall
        rar
        ripgrep
        wget
        home-manager
      ]
      ++ (lib.optional isNixOS libreoffice)
      # handle fonts
      ++ (lib.optionals (!isNixOS) config.iynaix.fonts.packages);

    # copy wallpapers
    file."Pictures/Wallpapers/gits-catppuccin.jpg" = {
      source = ./gits-catppuccin.jpg;
      recursive = true;
    };
  };
}
