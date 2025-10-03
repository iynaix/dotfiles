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
    getExe'
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
  wallpapers_dir = "${config.hj.directory}/Pictures/Wallpapers";
  walls_in_dir = "${config.hj.directory}/Pictures/wallpapers_in";
in
{
  options.custom = {
    programs = {
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
            useDedupe = config.custom.programs.wallpaper-tools.enable;
            useRclip = config.custom.programs.rclip.enable;
            useWallfacer = config.custom.programs.wallfacer.enable;
          };
          description = "Package to use for dotfiles-rs";
        };
      };
    };
  };

  config = mkIf config.custom.isWm (mkMerge [
    {
      environment = {
        shellAliases = {
          wall = "wallpaper";
        };
        systemPackages = [
          config.custom.programs.dotfiles.package
          pkgs.swww
        ];
      };

      # handle setting the wallpaper on startup
      # start swww and wallpaper via systemd to minimize reloads
      systemd.user.services =
        let
          wallpaper-startup = pkgs.writeShellApplication {
            name = "wallpaper-startup";
            runtimeInputs = [ config.custom.programs.dotfiles.package ];
            text = ''
              wallpaper "$@"
              ${optionalString (config.custom.wm == "hyprland") "hypr-monitors"}
            '';
          };
        in
        {
          # adapted from home-manager:
          # https://github.com/nix-community/home-manager/blob/master/modules/services/swww.nix
          swww = {
            wantedBy = [ "graphical-session.target" ];

            unitConfig = {
              ConditionEnvironment = "WAYLAND_DISPLAY";
              Description = "swww-daemon";
              After = [ "graphical-session.target" ];
              PartOf = [ "graphical-session.target" ];
            };

            serviceConfig = {
              ExecStart = getExe' pkgs.swww "swww-daemon";
              Restart = "always";
              RestartSec = 10;
            };
          };
          wallpaper = {
            wantedBy = [ "swww.service" ];
            unitConfig = {
              Description = "Set the wallpaper and update colorscheme";
              PartOf = [ "graphical-session.target" ];
              After = [ "swww.service" ];
              Requires = [ "swww.service" ];
            };
            serviceConfig = {
              Type = "oneshot";
              ExecStart = getExe wallpaper-startup;
              ExecReload = "${getExe wallpaper-startup} reload";
            };
          };
        };

      # add separate window rules to set dimensions for each monitor for rofi-wallpaper, this is so ugly :(
      custom.programs.niri = {
        settings.window-rules = map (
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
        ) config.custom.hardware.monitors;
      };
    }

    (mkIf config.custom.programs.wallfacer.enable {
      custom.shell.packages = {
        wallfacer =
          let
            wallfacerConf = {
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
            };
          in
          {
            text =
              # workaround for Error 71 (Protocol error) dispatching to Wayland display. (nvidia only?)
              # https://github.com/tauri-apps/tauri/issues/10702
              lib.optionalString config.custom.hardware.nvidia.enable ''
                export WEBKIT_DISABLE_DMABUF_RENDERER=1
              ''
              + libCustom.direnvCargoRun {
                dir = "/persist${config.hj.directory}/projects/wallfacer";
                args = "--config ${tomlFormat.generate "wallfacer.toml" wallfacerConf}";
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
    })

    (mkIf config.custom.programs.wallpaper-tools.enable {
      custom = {
        shell.packages = {
          # fetch wallpapers from pixiv for user
          pixiv = libCustom.direnvCargoRun {
            dir = "/persist${config.hj.directory}/projects/pixiv";
          };
        };

        programs.pqiv.settings = mkAfter ''
          c { command(nomacs $1) }
          m { command(mv $1 ${walls_in_dir}) }
        '';
      };

      environment.systemPackages = [ pkgs.nomacs ];

      custom.persist = {
        home = {
          directories = [
            ".cache/czkawka"
            ".config/nomacs"
          ];
        };
      };
    })

    (mkIf config.custom.programs.rclip.enable {
      environment = {
        systemPackages = [ pkgs.rclip ];

        shellAliases = {
          wallrg = "wallpaper search -t 50";
        };
      };

      custom.persist = {
        home = {
          directories = [
            ".cache/clip"
            ".cache/huggingface"
            ".config/Ultralytics"
          ];
          cache.directories = [ ".local/share/rclip" ];
        };
      };
    })
  ]);
}
