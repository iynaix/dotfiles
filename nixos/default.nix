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
      ++ (lib.optional config.home-manager.users.${user}.iynaix.helix.enable helix);

    programs.file-roller.enable = true;

    # fix gparted "cannot open display: :0" error
    # see: https://askubuntu.com/questions/939938/gparted-cannot-open-display
    home-manager.users.${user} = {
      gtk.gtk3.bookmarks = lib.optionals config.iynaix-nixos.hdds.enable [
        "file:///media/6TBRED/Anime/Current Anime Current"
        "file:///media/6TBRED/US/Current TV Current"
        "file:///media/6TBRED/Movies"
      ];

      iynaix.hyprland.extraBinds.exec-once = [
        "${pkgs.xorg.xhost}/bin/xhost +local:"
      ];
    };

    iynaix-nixos.persist.home.directories = [
      ".local/state/wireplumber"
    ];
  };
}
