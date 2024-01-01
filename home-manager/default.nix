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

  # setup fonts for other distros, run "fc-cache -f" to refresh fonts
  fonts.fontconfig.enable = true;

  home = {
    username = user;
    homeDirectory = "/home/${user}";
    # do not change this value
    stateVersion = "23.05";

    sessionVariables = {
      __IS_NIXOS =
        if isNixOS
        then "1"
        else "0";
      NIXPKGS_ALLOW_UNFREE = "1";
    };

    packages = with pkgs;
      [
        curl
        gzip
        killall
        rar # includes unrar
        ripgrep
        wget
        home-manager
        libreoffice
        trash-cli
        # misc utilities for dotfiles written in rust
        iynaix.dotfiles-utils
      ]
      ++ (lib.optional config.iynaix.helix.enable helix)
      # handle fonts
      ++ (lib.optionals (!isNixOS) config.iynaix.fonts.packages);
  };

  # Let Home Manager install and manage itself.
  programs.home-manager.enable = true;

  # stop bothering me
  xdg.configFile = {
    "nix/nix.conf".text = "experimental-features = nix-command flakes";
    "nixpkgs/config.nix".text = ''{ allowUnfree = true; }'';
  };

  iynaix.persist = {
    home.directories = [
      {
        directory = "Desktop";
        method = "symlink";
      }
      {
        directory = "Documents";
        method = "symlink";
      }
      {
        directory = "Pictures";
        method = "symlink";
      }
    ];
  };
}
