{ lib, ... }:
let
  inherit (lib)
    getExe
    getExe'
    max
    mkIf
    mkMerge
    mkOption
    optionalString
    ;
  inherit (lib.types) package;
in
{
  flake.nixosModules.core =
    { config, pkgs, ... }:
    {
      options.custom = {
        programs = {
          dotfiles = {
            package = mkOption {
              type = package;
              default = pkgs.custom.dotfiles-rs.override {
                inherit (config.custom) wm;
              };
              description = "Package to use for dotfiles-rs";
            };
          };
        };
      };
    };

  flake.nixosModules.wm =
    {
      config,
      pkgs,
      ...
    }:
    mkIf config.custom.isWm (mkMerge [
      {
        environment = {
          systemPackages = with pkgs; [
            config.custom.programs.dotfiles.package
            swww
            nomacs
          ];
        };

        custom.persist = {
          home = {
            directories = [
              ".cache/czkawka"
            ];
          };
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

      # rclip
      {
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
      }
    ]);
}
