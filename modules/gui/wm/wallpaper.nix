{
  tags = [ "wm" ];

  config =
    {
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
        custom.programs = {
          hyprland.settings = /* lua */ ''
            hl.window_rule({ match = { class = "wallpaper-selector" }, float = true, center = true })
          '';

          umbriel = {
            settings.window_rule = [
              {
                match.app_id = "wallpaper-selector";
                default_floating = true;
              }
            ];
          };
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
