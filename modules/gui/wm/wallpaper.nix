{ lib, ... }:
let
  inherit (lib) concatMapStringsSep max mkMerge;
in
{
  flake.nixosModules.wm =
    { config, pkgs, ... }:
    mkMerge [
      {
        environment = {
          systemPackages = with pkgs; [
            pkgs.custom.dotfiles-rs
            nomacs
          ];
        };

        # add separate window rules to set dimensions for each monitor for wallpaper selector, this is so ugly :(
        custom.programs.niri = {
          settings.config = concatMapStringsSep "\n" (
            mon:
            let
              targetPercent = 0.3;
              width = builtins.floor (builtins.div (targetPercent * (max mon.width mon.height)) mon.scale);
              # 16:9 ratio
              height = builtins.floor (width / 16.0 * 9.0);
            in
            /* kdl */ ''
              window-rule {
                  match title="^wallpaper-selector-${mon.name}$"
                  default-column-width { fixed ${toString width}; }
                  default-window-height { fixed ${toString height}; }
                  open-floating true
              }
            ''
          ) config.custom.hardware.monitors;
        };

        custom.persist = {
          home = {
            directories = [
              ".cache/czkawka"
            ];
          };
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
    ];
}
