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
  fonts.fontconfig.enable = true;

  home = {
    username = user;
    homeDirectory = "/home/${user}";
    # do not change this value
    stateVersion = "22.11";

    sessionVariables = {
      "NIXPKGS_ALLOW_UNFREE" = "1";
    };

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
        libreoffice
      ]
      # handle fonts
      ++ (lib.optionals (!isNixOS) config.iynaix.fonts.packages);

    # copy wallpapers
    file."Pictures/Wallpapers/gits-catppuccin.jpg" = {
      source = ./gits-catppuccin.jpg;
      recursive = true;
    };
  };

  xdg.configFile = lib.mkIf (!isNixOS) {
    "nix/nix.conf".text = "experimental-features = nix-command flakes";
  };
}
