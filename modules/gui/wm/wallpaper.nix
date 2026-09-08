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
                while ! noctalia msg status >/dev/null 2>&1; do
                  ${lib.getExe' pkgs.coreutils "sleep"} 0.5
                done

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
              RestartSec = 1;
              Restart = "on-failure";
              Type = "oneshot";
            };
            wantedBy = [ "noctalia.service" ];
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
