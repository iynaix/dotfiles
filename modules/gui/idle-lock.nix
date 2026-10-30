{
  tags = [ "wm" ];

  config =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      lock = pkgs.writeShellApplication {
        name = "lock";
        runtimeInputs = [ config.programs.noctalia.package ];
        text = /* sh */ ''
          ${lib.optionalString config.custom.lock.enable "noctalia msg session lock-and-suspend"}
          noctalia msg dpms-off
        '';
      };
    in
    {
      # NOTE: lock option is defined in gui/default.nix
      environment.systemPackages = [
        lock
      ];

      # lock on idle
      custom = {
        programs = {
          # disable suspend and lockscreen if host doesn't lock
          noctalia.settings = {
            idle.behavior.idle-behavior = {
              action = "screen_off";
              enabled = true;
              timeout = 5 * 60.0;
            };

            idle.behavior.lock-and-suspend = {
              action = "lock_and_suspend";
              enabled = config.custom.lock.enable;
              timeout = 5 * 60.0 + 10.0;
            };

          };

          umbriel.settings = {
            # manual lock keybind
            keybinds = {
              "Mod+Shift+Ctrl+x" = "spawn ${lib.getExe lock}";
            };

            events = {
              lid_open = lib.getExe lock;
            };
          };
        };
      };
    };
}
