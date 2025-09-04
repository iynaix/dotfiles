{
  config,
  lib,
  libCustom,
  pkgs,
  ...
}:
let
  inherit (lib)
    getExe
    makeBinPath
    max
    mkAfter
    mkEnableOption
    mkIf
    mkMerge
    mkOption
    optionalAttrs
    optionalString
    optionals
    ;
  inherit (lib.types) package;
  tomlFormat = pkgs.formats.toml { };
  wallpapers_dir = "${config.xdg.userDirs.pictures}/Wallpapers";
  walls_in_dir = "${config.xdg.userDirs.pictures}/wallpapers_in";
in
{
  options.custom = {
    rclip.enable = mkEnableOption "rclip";
    wallfacer.enable = mkEnableOption "wallfacer";
    wallpaper-tools.enable = mkEnableOption "additional tools for wallpapers, e.g. fetching and editing";
    dotfiles = {
      package = mkOption {
        type = package;
        default = pkgs.custom.dotfiles-rs.override {
          inherit (config.custom) wm;
          pqiv = pkgs.pqiv.overrideAttrs (o: {
            patches =
              (o.patches or [ ])
              # fix window resizing on the first image in niri if called in a keybind
              ++ optionals (config.custom.wm == "niri") [ ../niri/pqiv-gdk-wayland.patch ];
          });
          swww = config.services.swww.package;
          wallust = config.programs.wallust.package;
          useDedupe = config.custom.wallpaper-tools.enable;
          useRclip = config.custom.rclip.enable;
          useWallfacer = config.custom.wallfacer.enable;
        };
        description = "Package to use for dotfiles-rs";
      };
    };
  };

  config = mkIf config.custom.isWm (mkMerge [
    {
      home = {
        shellAliases = {
          wall = "wallpaper";
        };
        packages = [ config.custom.dotfiles.package ];
      };

      # handle setting the wallpaper on startup
      # start swww and wallpaper via systemd to minimize reloads
      services.swww.enable = true;

      systemd.user.services =
        let
          wallpaper-startup = pkgs.writeShellApplication {
            name = "wallpaper-startup";
            runtimeInputs = [ config.custom.dotfiles.package ];
            text = ''
              wallpaper "$@"
              ${optionalString (config.custom.wm == "hyprland") "hypr-monitors"}
            '';
          };
        in
        {
          # swww has a runtime dependency on "pidof", needed for mangowc
          # remove when https://github.com/NixOS/nixpkgs/pull/433265 is merged
          swww = {
            Service.Environment = "PATH=${makeBinPath [ pkgs.procps ]}";
          };

          wallpaper = {
            Install.WantedBy = [ "swww.service" ];
            Unit = {
              Description = "Set the wallpaper and update colorscheme";
              PartOf = [ config.wayland.systemd.target ];
              After = [ "swww.service" ];
              Requires = [ "swww.service" ];
            };
            Service = {
              Type = "oneshot";
              ExecStart = getExe wallpaper-startup;
              ExecReload = "${getExe wallpaper-startup} reload";
              X-SwitchMethod = "keep-old";
            };
          };
        };

      # add separate window rules to set dimensions for each monitor for rofi-wallpaper, this is so ugly :(
      programs.niri.settings.window-rules = map (
        mon:
        let
          targetPercent = 0.3;
          width = builtins.floor (builtins.div (targetPercent * (max mon.width mon.height)) mon.scale);
          # 16:9 ratio
          height = builtins.floor (width / 16.0 * 9.0);
        in
        {
          matches = [ { title = "^wallpaper-rofi-${mon.name}$"; } ];
          open-floating = true;
          default-column-width.fixed = width;
          default-window-height.fixed = height;
        }
      ) config.custom.monitors;
    }

    (mkIf config.custom.wallfacer.enable {
      custom.shell.packages = {
        wallfacer = {
          text =
            # workaround for Error 71 (Protocol error) dispatching to Wayland display. (nvidia only?)
            # https://github.com/tauri-apps/tauri/issues/10702
            lib.optionalString config.custom.nvidia.enable ''
              export WEBKIT_DISABLE_DMABUF_RENDERER=1
            ''
            + libCustom.direnvCargoRun {
              dir = "/persist${config.home.homeDirectory}/projects/wallfacer";
            };
          # completion for wallpaper gui, bash completion isn't helpful as there are 1000s of images
          fishCompletion = # fish
            ''
              function _wallfacer_gui
                find ${wallpapers_dir} -maxdepth 1 -name "*.webp"
              end
              complete -c wallfacer -n '__fish_seen_subcommand_from gui' -a '(_wallfacer_gui)'
            '';
        };
      };

      # config file for wallfacer
      xdg.configFile = {
        "wallfacer/wallfacer.toml".source = tomlFormat.generate "wallfacer.toml" (
          {
            wallpapers_path = wallpapers_dir;
            min_width = 3840; # 4k width
            min_height = 2880; # lg dualup height
            show_faces = false;

            resolutions = [
              {
                name = "FW";
                description = "Framework";
                resolution = "2880x1920";
              }
              {
                name = "HD";
                description = "Full HD (1920x1080)";
                resolution = "1920x1080";
              }
              {
                name = "Thumb";
                description = "Square";
                resolution = "1x1";
              }
              {
                name = "UW";
                description = "Ultrawide 34 inch";
                resolution = "3440x1440";
              }
              {
                name = "Vert";
                description = "Vertical 1440p";
                resolution = "1440x2560";
              }
              {
                name = "FW Vert";
                description = "Framework Vertical";
                resolution = "1504x2256";
              }
            ];
          }
          // optionalAttrs config.custom.isWm {
            wallpaper_command = "wallpaper $1";
          }
        );
      };
    })

    (mkIf config.custom.wallpaper-tools.enable {
      custom.shell.packages = {
        # fetch wallpapers from pixiv for user
        pixiv = libCustom.direnvCargoRun {
          dir = "/persist${config.home.homeDirectory}/projects/pixiv";
        };
      };

      home.packages = [ pkgs.nomacs ];

      programs.pqiv.extraConfig = mkAfter ''
        c { command(nomacs $1) }
        m { command(mv $1 ${walls_in_dir}) }
      '';

      custom.persist = {
        home = {
          directories = [
            ".cache/czkawka"
            ".config/nomacs"
          ];
        };
      };
    })

    (mkIf config.custom.rclip.enable {
      home = {
        packages = [ pkgs.rclip ];

        shellAliases = {
          wallrg = "wallpaper search -t 50";
        };
      };

      custom.persist = {
        home = {
          directories = [
            ".cache/clip"
            ".cache/huggingface"
          ];
          cache.directories = [ ".local/share/rclip" ];
        };
      };
    })
  ]);
}
