{
  pkgs,
  config,
  lib,
  ...
}: {
  imports = [
    ./docker.nix
    ./keyring.nix
    ./overlays.nix
    ./sonarr.nix
    ./transmission.nix
    ./virt-manager.nix
  ];

  config = {
    environment.systemPackages = with pkgs;
      [
        gcr # stops errors with copilot login?
        gparted
        libnotify
        # for nixlang
        alejandra
        nil
      ]
      ++ (lib.optional config.iynaix.helix.enable helix);

    iynaix.hyprland.extraBinds.exec-once = [
      # fix gparted "cannot open display: :0" error
      # see: https://askubuntu.com/questions/939938/gparted-cannot-open-display
      "${pkgs.xorg.xhost}/bin/xhost +local:"
    ];

    iynaix.persist.home.directories = [
      ".local/state/wireplumber"
    ];
  };
}
