{
  pkgs,
  config,
  lib,
  user,
  ...
}: let
  hmCfg = config.home-manager.users.${user};
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
    # automount disks
    services.gvfs.enable = true;

    # execute shebangs that assume hardcoded shell paths
    services.envfs.enable = true;

    environment = {
      etc = {
        # git
        "gitconfig".text = hmCfg.xdg.configFile."git/config".text;
        # lf
        "lf/lfrc".text = hmCfg.xdg.configFile."lf/lfrc".text;
        "lf/icons".text = hmCfg.xdg.configFile."lf/icons".text;
      };
      variables = {
        STARSHIP_CONFIG = "${hmCfg.xdg.configHome}/starship.toml";
      };

      systemPackages = with pkgs;
        [
          gcr # stops errors with copilot login?
          libnotify
          lf
          # for nixlang
          alejandra
          nil
          nixpkgs-fmt
        ]
        ++ (lib.optional (!config.services.xserver.desktopManager.gnome.enable) hmCfg.iynaix.terminal.fakeGnomeTerminal)
        ++ (lib.optional config.iynaix-nixos.distrobox.enable pkgs.distrobox)
        ++ (lib.optional hmCfg.iynaix.helix.enable helix);
    };

    # set up programs to use same config as home-manager
    programs.bash = {
      interactiveShellInit = hmCfg.programs.bash.initExtra;
      loginShellInit = hmCfg.programs.bash.profileExtra;
    };

    programs.file-roller.enable = true;

    iynaix-nixos.persist.home.directories = [
      ".local/state/wireplumber"
    ];
  };
}
