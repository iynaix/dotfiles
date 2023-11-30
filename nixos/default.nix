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
    ./am5.nix
    ./audio.nix
    ./auth.nix
    ./configuration.nix
    ./docker.nix
    ./filezilla.nix
    ./gnome3.nix
    ./hdds.nix
    ./hyprland.nix
    ./impermanence.nix
    ./kanata.nix
    ./nix.nix
    ./nvidia.nix
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
    # services.devmon.enable = true;

    environment = {
      etc = {
        # git
        "gitconfig".text = hmCfg.xdg.configFile."git/config".text;
      };
      variables = {
        TERMINAL = hmCfg.iynaix.terminal.exec;
        EDITOR = "nvim";
        VISUAL = "nvim";
        NIXPKGS_ALLOW_UNFREE = "1";
        STARSHIP_CONFIG = "${hmCfg.xdg.configHome}/starship.toml";
      };

      systemPackages = with pkgs;
        [
          curl
          eza
          killall
          neovim
          ntfs3g
          procps
          ripgrep
          tree # for root, normal user has an eza alias
          wget
        ]
        ++ (lib.optional (!config.services.xserver.desktopManager.gnome.enable) hmCfg.iynaix.terminal.fakeGnomeTerminal)
        ++ (lib.optional config.iynaix-nixos.distrobox.enable pkgs.distrobox)
        ++ (lib.optional hmCfg.iynaix.helix.enable helix);
    };

    # setup fonts
    fonts.packages = hmCfg.iynaix.fonts.packages;

    # set up programs to use same config as home-manager
    programs.bash = {
      interactiveShellInit = hmCfg.programs.bash.initExtra;
      loginShellInit = hmCfg.programs.bash.profileExtra;
    };

    # bye bye nano
    programs.nano.enable = lib.mkForce false;

    programs.file-roller.enable = true;

    iynaix-nixos.persist = {
      root.directories = lib.mkIf hmCfg.iynaix.wifi.enable [
        "/etc/NetworkManager"
      ];

      home.directories = [
        ".local/state/wireplumber"
      ];
    };
  };
}
