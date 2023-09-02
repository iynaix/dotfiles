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
      "__IS_NIXOS" =
        if isNixOS
        then "1"
        else "0";
      "NIXPKGS_ALLOW_UNFREE" = "1";
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
      ]
      ++ (lib.optional config.iynaix.helix.enable helix)
      # handle fonts
      ++ (lib.optionals (!isNixOS) config.iynaix.fonts.packages);
  };

  xdg.configFile = lib.mkIf (!isNixOS) {
    "nix/nix.conf".text = "experimental-features = nix-command flakes";
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
