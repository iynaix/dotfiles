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
    ./tty.nix
    ./users.nix
    ./vercel.nix
    ./virt-manager.nix
    ./zfs.nix
  ];

  options.custom = with lib; {
    shell = {
      packages = mkOption {
        type =
          with types;
          attrsOf (oneOf [
            str
            attrs
            package
          ]);
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
  };

  config =
    let
      nixosShellPkgs = lib.custom.mkShellPackages config.custom.shell.packages;
      hmShellPkgs = lib.custom.mkShellPackages config.hm.custom.shell.packages;
    in
    {
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
              t # eza related
              y # yazi
              ;
          };

        systemPackages =
          with pkgs;
          [
            curl
            eza
            killall
            neovim
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
          ++ (lib.attrValues nixosShellPkgs)
          ++ (lib.optional config.hm.custom.helix.enable helix);
      };

      # add custom user created shell packages to pkgs.custom.shell
      nixpkgs.overlays = [
        (_: prev: {
          custom = prev.custom // {
            shell = nixosShellPkgs // hmShellPkgs;
          };
        })
      ];

      # create symlink to dotfiles from default location
      systemd.tmpfiles.rules = [
        "L+ /etc/nixos - - - - /persist${config.hm.home.homeDirectory}/projects/dotfiles"
      ];

      # setup fonts
      fonts = {
        enableDefaultPackages = true;
        inherit (config.hm.custom.fonts) packages;
      };

      programs = {
        # use same config as home-manager
        bash.interactiveShellInit = config.hm.programs.bash.initExtra;

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

      # faster boot times
      # systemd.services.NetworkManager-wait-online.enable = false;

      custom.persist = {
        root.directories = lib.mkIf config.hm.custom.wifi.enable [ "/etc/NetworkManager" ];

        home.directories = [ ".local/state/wireplumber" ];
      };
    };
}
