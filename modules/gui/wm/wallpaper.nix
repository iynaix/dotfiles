{
  tags = [ "wm" ];

  config =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    lib.mkMerge [
      {
        environment = {
          systemPackages = with pkgs; [
            nomacs
          ];
        };

        # add separate window rules to set dimensions for each monitor for wallpaper selector, this is so ugly :(
        custom.programs.umbriel = {
          settings.window_rule = map (
            mon:
            let
              targetPercent = 0.3;
              width = builtins.floor (builtins.div (targetPercent * (lib.max mon.width mon.height)) mon.scale);
              # 16:9 ratio
              height = builtins.floor (width / 16.0 * 9.0);
            in
            {
              match.title = "wallpaper-selector-${mon.name}";
              default_floating = true;
              default_position = {
                x = 0;
                y = 0;
              };
              default_size = [
                width
                height
              ];
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
