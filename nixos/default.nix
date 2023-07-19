{
  pkgs,
  config,
  lib,
  ...
}: {
  imports = [
    ./audio.nix
    ./docker.nix
    ./gnome3.nix
    ./hardware
    ./hyprland.nix
    ./impermanence.nix
    ./keyring.nix
    ./kmonad.nix
    ./overlays.nix
    ./sonarr.nix
    ./transmission.nix
    ./virt-manager.nix
    ./zfs.nix
    ./zsh.nix
  ];

  config = {
    services.gvfs.enable = true;

    environment.systemPackages = with pkgs;
      [
        gcr # stops errors with copilot login?
        gparted
        libnotify
        # for nixlang
        alejandra
        nil
      ]
      ++ (lib.optional config.iynaix-nixos.helix.enable helix);

    # fix gparted "cannot open display: :0" error
    # see: https://askubuntu.com/questions/939938/gparted-cannot-open-display
    environment.shellInit = "${pkgs.xorg.xhost}/bin/xhost +local:";

    iynaix.persist.home.directories = [
      ".local/state/wireplumber"
    ];
  };
}
