{
  pkgs,
  config,
  lib,
  host,
  user,
  ...
}: let
  hmConfig = config.home-manager.users.${user};
in {
  imports =
    [
      ./audio.nix
      ./auth.nix
      ./docker.nix
      ./filezilla.nix
      ./gnome3.nix
      ./hardware
      ./hyprland.nix
      ./impermanence.nix
      ./nix.nix
      ./sonarr.nix
      ./sops.nix
      ./syncoid.nix
      ./transmission.nix
      ./vercel.nix
      ./virt-manager.nix
      ./zfs.nix
    ]
    ++ (lib.optionals (host == "laptop") [./kmonad.nix]);

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
      ++ (lib.optional (!config.services.xserver.desktopManager.gnome.enable) hmConfig.iynaix.terminal.fakeGnomeTerminal)
      ++ (lib.optional config.iynaix-nixos.distrobox.enable pkgs.distrobox)
      ++ (lib.optional hmConfig.iynaix.helix.enable helix);

    programs.file-roller.enable = true;

    # fix gparted "cannot open display: :0" error
    # see: https://askubuntu.com/questions/939938/gparted-cannot-open-display
    home-manager.users.${user} = {
      wayland.windowManager.hyprland.settings = {
        exec-once = [
          # fix gparted "cannot open display: :0" error
          "${pkgs.xorg.xhost}/bin/xhost +local:"
          # fix Authorization required, but no authorization protocol specified error
          "${pkgs.xorg.xhost}/bin/xhost si:localuser:root"
        ];
      };
    };

    iynaix-nixos.persist.home.directories = [
      ".local/state/wireplumber"
    ];
  };
}
