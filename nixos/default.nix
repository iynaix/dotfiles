{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    attrValues
    getExe
    mapAttrsToList
    mkForce
    mkIf
    mkOption
    optional
    optionals
    ;
  inherit (lib.types)
    attrs
    attrsOf
    oneOf
    package
    str
    ;
in
{
  imports = [
    ./audio.nix
    ./auth.nix
    ./bluetooth.nix
    ./boot.nix
    ./configuration.nix
    ./docker.nix
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
    ./specialisations.nix
    ./syncoid.nix
    ./transmission.nix
    ./users.nix
    ./vercel.nix
    ./virt-manager.nix
    ./zfs.nix
  ];

  options.custom = {
    shell = {
      packages = mkOption {
        type = attrsOf (oneOf [
          str
          attrs
          package
        ]);
        apply = lib.custom.mkShellPackages;
        default = { };
        description = ''
          Attrset of shell packages to install and add to pkgs.custom overlay (for compatibility across multiple shells).
          Both string and attr values will be passed as arguments to writeShellApplicationCompletions
        '';
        example = ''
          shell.packages = {
            myPackage1 = "echo 'Hello, World!'";
            myPackage2 = {
              runtimeInputs = [ pkgs.hello ];
              text = "hello --greeting 'Hi'";
            };
          }
        '';
      };
    };
    symlinks = mkOption {
      type = attrsOf str;
      default = { };
      description = "Symlinks to create in the format { dest = src;}";
    };
  };

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
        "xdg/gtk-4.0/settings.ini".text = config.hm.xdg.configFile."gtk-4.0/settings.ini".text;
      };

      # install fish completions for fish
      # https://github.com/nix-community/home-manager/pull/2408
      pathsToLink = [ "/share/fish" ];

      variables = {
        TERMINAL = getExe config.hm.custom.terminal.package;
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
            t # eza related
            y # yazi
            ;
        };

      systemPackages =
        with pkgs;
        [
          curl
          eza
          (hiPrio procps) # for uptime
          ripgrep
          yazi
          zoxide
          # use the package configured by nvf
          custom.neovim-iynaixos
        ]
        ++
          # install gtk theme for root, some apps like gparted only run as root
          [
            config.hm.gtk.theme.package
            config.hm.gtk.iconTheme.package
          ]
        # add custom user created shell packages
        ++ (attrValues config.custom.shell.packages)
        ++ (optional config.hm.custom.helix.enable helix);
    };

    # add custom user created shell packages to pkgs.custom.shell
    nixpkgs.overlays = [
      (_: prev: {
        custom = prev.custom // {
          shell = config.custom.shell.packages // config.hm.custom.shell.packages;
        };
      })
    ];

    # create symlink to dotfiles from default /etc/nixos
    custom.symlinks = {
      "/etc/nixos" = "/persist${config.hm.home.homeDirectory}/projects/dotfiles";
    };

    # create symlinks
    systemd.tmpfiles.rules = [
      # cleanup systemd coredumps once a week
      "D! /var/lib/systemd/coredump root root 7d"
    ] ++ (mapAttrsToList (dest: src: "L+ ${dest} - - - - ${src}") config.custom.symlinks);

    # setup fonts
    fonts = {
      enableDefaultPackages = true;
      inherit (config.hm.custom.fonts) packages;
    };

    programs = {
      # use same config as home-manager
      bash.interactiveShellInit = config.hm.programs.bash.initExtra;

      file-roller.enable = true;
      git.enable = true;

      # bye bye nano
      nano.enable = mkForce false;
    };

    # use gtk theme on qt apps
    qt = mkIf (!config.hm.custom.headless) {
      enable = true;
      platformTheme = "qt5ct";
      style = "kvantum";
    };

    xdg = {
      # use mimetypes defined from home-manager
      mime =
        let
          hmMime = config.hm.xdg.mimeApps;
        in
        {
          enable = true;
          inherit (hmMime) defaultApplications;
          addedAssociations = hmMime.associations.added;
          removedAssociations = hmMime.associations.removed;
        };

      # fix opening terminal for nemo / thunar by using xdg-terminal-exec spec
      terminal-exec = {
        enable = true;
        settings = {
          default = [ "${config.hm.custom.terminal.package.pname}.desktop" ];
        };
      };
    };

    custom.persist = {
      root.directories = optionals config.hm.custom.wifi.enable [ "/etc/NetworkManager" ];
      root.cache.directories = [
        "/var/lib/systemd/coredump"
      ];

      home.directories = [ ".local/state/wireplumber" ];
    };
  };
}
