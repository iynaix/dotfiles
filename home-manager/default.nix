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
    stateVersion = "23.05";

    sessionVariables = {
      "__IS_NIXOS" =
        if isNixOS
        then "1"
        else "0";
      "NIXPKGS_ALLOW_UNFREE" = "1";
      # silence direnv
      "DIRENV_LOG_FORMAT" = "";
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

    # copy wallpapers
    file."Pictures/Wallpapers/gits-catppuccin.jpg".source = ./gits-catppuccin.jpg;
  };

  xdg.configFile = lib.mkIf (!isNixOS) {
    "nix/nix.conf".text = "experimental-features = nix-command flakes";
  };

  # prevent symlink error for impermanence
  # home.file."${config.xdg.cacheHome}/.keep".force = true;
  # home.file.".cache/.keep".enable = lib.mkForce false;
  # home.file."${config.xdg.cacheHome}/.keep".enable = lib.mkForce false;

  # iynaix.persist.home = {
  #   directories = [
  #     ".local/state/home-manager"
  #     ".local/state/nix/profiles"
  #   ];
  # };
}
