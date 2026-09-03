{
  tags = [ "wm" ];

  config =
    {
      config,
      lib,
      pkgs,
      tags,
      ...
    }:
    lib.mkMerge [
      {
        environment = {
          systemPackages = with pkgs; [
            nomacs
          ];
        };

        systemd.user.services.wallpaper =
          let
            wallpaper-init = pkgs.writeShellApplication {
              name = "wallpaper-init";
              runtimeInputs = [
                config.programs.noctalia.package
                config.custom.programs.dotfiles-rs
              ];
              text = /* sh */ ''
                # hide on laptop screens to save space
                ${lib.optionalString (builtins.elem "laptop" tags) "noctalia msg bar-hide"}
                wallpaper
              '';
            };
          in
          {
            description = "Changes the wallpaper on boot";
            unitConfig = {
              After = [ "noctalia.service" ];
              Requires = [ "noctalia.service" ];
            };
            serviceConfig = {
              ExecStart = lib.getExe wallpaper-init;
              ExecStartPre = "${lib.getExe' pkgs.coreutils "sleep"} 3";
              RestartSec = 1;
              Restart = "on-failure";
              Type = "oneshot";
            };
            wantedBy = [ "noctalia.service" ];
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
                anchor = "center";
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
