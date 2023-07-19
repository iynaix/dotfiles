{
  pkgs,
  config,
  lib,
  user,
  ...
}: {
  imports = [
    ./audio.nix
    ./docker.nix
    ./filezilla.nix
    ./gnome3.nix
    ./hardware
    ./hyprland.nix
    ./impermanence.nix
    ./keyring.nix
    ./kmonad.nix
    ./nemo.nix
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
      ++ (lib.optional config.iynaix-nixos.distrobox.enable pkgs.distrobox)
      ++ (lib.optional config.iynaix-nixos.helix.enable helix);

    # fix gparted "cannot open display: :0" error
    # see: https://askubuntu.com/questions/939938/gparted-cannot-open-display
    home-manager.users.${user} = {
      iynaix.hyprland.extraBinds.exec-once = [
        "${pkgs.xorg.xhost}/bin/xhost +local:"
      ];
    };

    iynaix-nixos.persist.home.directories = [
      ".local/state/wireplumber"
    ];
  };
}
