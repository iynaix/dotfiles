{
  pkgs,
  config,
  lib,
  user,
  ...
}: let
  hmConfig = config.home-manager.users.${user};
in {
  imports = [
    ./audio.nix
    ./auth.nix
    ./docker.nix
    ./filezilla.nix
    ./gnome3.nix
    ./hardware
    ./hyprland.nix
    ./impermanence.nix
    ./kmonad.nix
    ./nix.nix
    ./sonarr.nix
    ./sops.nix
    ./syncoid.nix
    ./transmission.nix
    ./vercel.nix
    ./virt-manager.nix
    ./zfs.nix
  ];

  config = {
    services.gvfs.enable = true;

    environment.systemPackages = with pkgs;
      [
        gcr # stops errors with copilot login?
        libnotify
        # for nixlang
        alejandra
        nil
        nixpkgs-fmt
      ]
      ++ (lib.optional (!config.services.xserver.desktopManager.gnome.enable) hmConfig.iynaix.terminal.fakeGnomeTerminal)
      ++ (lib.optional config.iynaix-nixos.distrobox.enable pkgs.distrobox)
      ++ (lib.optional hmConfig.iynaix.helix.enable helix);

    programs.file-roller.enable = true;

    iynaix-nixos.persist.home.directories = [
      ".local/state/wireplumber"
    ];
  };
}
