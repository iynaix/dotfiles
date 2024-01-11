{
  pkgs,
  config,
  lib,
  ...
}: {
  imports = [
    ./audio.nix
    ./auth.nix
    ./bluetooth.nix
    ./configuration.nix
    ./docker.nix
    ./filezilla.nix
    ./gh.nix
    ./hdds.nix
    ./hyprland.nix
    ./impermanence.nix
    ./keyd.nix
    ./nix.nix
    ./nvidia.nix
    ./plasma.nix
    ./sonarr.nix
    ./sops.nix
    ./syncoid.nix
    ./transmission.nix
    ./users.nix
    ./vercel.nix
    ./virt-manager.nix
    ./zfs.nix
  ];

  config = {
    # automount disks
    services.gvfs.enable = true;
    # services.devmon.enable = true;
    programs.dconf.enable = true;

    environment = {
      etc = {
        # git
        "gitconfig".text = config.hm.xdg.configFile."git/config".text;
      };
      variables = {
        TERMINAL = config.hm.iynaix.terminal.exec;
        EDITOR = "nvim";
        VISUAL = "nvim";
        NIXPKGS_ALLOW_UNFREE = "1";
        STARSHIP_CONFIG = "${config.hm.xdg.configHome}/starship.toml";
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
        ++ (lib.optional (!config.services.xserver.desktopManager.gnome.enable) config.hm.iynaix.terminal.fakeGnomeTerminal)
        ++ (lib.optional config.iynaix-nixos.distrobox.enable pkgs.distrobox)
        ++ (lib.optional config.hm.iynaix.helix.enable helix);
    };

    # setup fonts
    fonts.packages = config.hm.iynaix.fonts.packages ++ [pkgs.iynaix.rofi-themes];

    programs = {
      # use same config as home-manager
      bash = {
        interactiveShellInit = config.hm.programs.bash.initExtra;
        loginShellInit = config.hm.programs.bash.profileExtra;
      };

      # bye bye nano
      nano.enable = lib.mkForce false;

      file-roller.enable = true;
    };

    # use gtk theme on qt apps
    qt = {
      enable = true;
      platformTheme = "gnome";
      style = "adwaita-dark";
    };

    iynaix-nixos.persist = {
      root.directories = lib.mkIf config.hm.iynaix.wifi.enable [
        "/etc/NetworkManager"
      ];

      home.directories = [
        ".local/state/wireplumber"
      ];
    };
  };
}
