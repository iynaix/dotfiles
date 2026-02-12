{ lib, ... }:
{
  flake.nixosModules.wm =
    { config, pkgs, ... }:
    lib.mkMerge [
      {
        environment = {
          systemPackages = with pkgs; [
            nomacs
          ];
        };

        # add separate window rules to set dimensions for each monitor for wallpaper selector, this is so ugly :(
        custom.programs.niri = {
          settings.window-rules = map (
            mon:
            let
              targetPercent = 0.3;
              width = builtins.floor (builtins.div (targetPercent * (lib.max mon.width mon.height)) mon.scale);
              # 16:9 ratio
              height = builtins.floor (width / 16.0 * 9.0);
            in
            {
              matches = [ { title = "^wallpaper-selector-${mon.name}$"; } ];
              default-column-width.fixed = width;
              default-window-height.fixed = height;
              open-floating = true;
            }
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
