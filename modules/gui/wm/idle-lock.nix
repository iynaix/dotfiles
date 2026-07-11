{ lib, ... }:
{
  flake.modules.nixos.core =
    { config, ... }:
    {
      options.custom = {
        lock.enable = lib.mkEnableOption "screen locking of host" // {
          default = config.custom.constants.isLaptop;
        };
      };
    };

  flake.modules.nixos.wm =
    { config, pkgs, ... }:
    let
      lock = pkgs.writeShellApplication {
        name = "lock";
        runtimeInputs = [ pkgs.noctalia ];
        text = /* sh */ ''
          ${lib.optionalString config.custom.lock.enable "noctalia msg session lock-and-suspend"}
          noctalia msg dpms-off
        '';
      };
    in
    {
      environment.systemPackages = [
        lock
      ];

      # lock on idle
      custom = {
        programs = {
          # disable suspend and lockscreen if host doesn't lock
          noctalia.settings = {
            idle.behavior.lock-and-suspend = {
              action = "lock_and_suspend";
              enabled = config.custom.lock.enable;
              timeout = 5 * 60.0;
            };

            idle.behavior.screen-off = {
              action = "lock_and_screen_off";
              enabled = true;
              timeout = 5 * 60.0;
            };
          };

          # handle laptop lid on the WMs
          hyprland.settings = /* lua */ ''
            hl.bind(mod .. " + SHIFT + CTRL + x", hl.dsp.exec_cmd("${lib.getExe lock}"))

            hl.bind("switch:Lid Switch", hl.dsp.exec_cmd("${lib.getExe lock}"), { locked = true })
          '';

          niri.settings.switch-events = {
            lid-open = {
              spawn = lib.getExe lock;
            };
          };

          mango.settings.bind = [ "$mod+SHIFT+CTRL, x, spawn, ${lib.getExe lock}" ];
        };

        # manual lock keybind
        wm.binds = {
          "Mod+Shift+Ctrl+x".spawn = lib.getExe lock;
        };
      };
    };
}
