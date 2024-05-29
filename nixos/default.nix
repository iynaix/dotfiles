{
  config,
  lib,
  pkgs,
  ...
}:
{
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
    ./qmk.nix
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
        # universal git settings
        "gitconfig".text = config.hm.xdg.configFile."git/config".text;
        # get gparted to use system theme
        "xdg/gtk-3.0/settings.ini".text = config.hm.xdg.configFile."gtk-3.0/settings.ini".text;
      };

      # install fish completions for fish
      # https://github.com/nix-community/home-manager/pull/2408
      pathsToLink = [ "/share/fish" ];

      variables = {
        TERMINAL = lib.getExe config.hm.custom.terminal.package;
        EDITOR = "nvim";
        VISUAL = "nvim";
        NIXPKGS_ALLOW_UNFREE = "1";
        STARSHIP_CONFIG = "${config.hm.xdg.configHome}/starship.toml";
      };

      # use some shell aliases from home manager
      shellAliases =
        {
          inherit (config.hm.programs.bash.shellAliases)
            eza
            ls
            ll
            la
            lla
            ;
        }
        // {
          inherit (config.hm.home.shellAliases)
            # eza related
            t
            tree
            # yazi
            y
            ;
        };

      systemPackages =
        with pkgs;
        [
          curl
          eza
          killall
          neovim
          ntfs3g
          procps
          ripgrep
          yazi
          zoxide
        ]
        ++
          # install gtk theme for root, some apps like gparted only run as root
          (with config.hm.gtk; [
            theme.package
            iconTheme.package
          ])
        # add custom user created shell packages
        ++ (lib.attrValues config.custom.shell.finalPackages)
        ++ (lib.optional config.hm.custom.helix.enable helix);
    };

    # add custom user created shell packages to pkgs.custom.shell
    nixpkgs.overlays = [
      (_: prev: {
        custom = prev.custom // {
          shell = config.custom.shell.finalPackages // config.hm.custom.shell.finalPackages;
        };
      })
    ];

    # setup fonts
    fonts = {
      enableDefaultPackages = true;
      inherit (config.hm.custom.fonts) packages;
    };

    programs = {
      # use same config as home-manager
      bash = {
        interactiveShellInit = config.hm.programs.bash.initExtra;
        loginShellInit = config.hm.programs.bash.profileExtra;
      };

      file-roller.enable = true;

      # bye bye nano
      nano.enable = lib.mkForce false;
    };

    # use gtk theme on qt apps
    qt = {
      enable = true;
      platformTheme = "gnome";
      style = "adwaita-dark";
    };

    # faster boot times
    # systemd.services.NetworkManager-wait-online.enable = false;

    custom.persist = {
      root.directories = lib.mkIf config.hm.custom.wifi.enable [ "/etc/NetworkManager" ];

      home.directories = [ ".local/state/wireplumber" ];
    };
  };
}
