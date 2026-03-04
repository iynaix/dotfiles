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
      inherit (config.custom.constants) isLaptop;
      lock = pkgs.writeShellApplication {
        name = "lock";
        runtimeInputs = [ pkgs.custom.noctalia-ipc ];
        text = /* sh */ ''
          ${lib.optionalString config.custom.lock.enable "noctalia-ipc sessionMenu lockAndSuspend"}
          noctalia-ipc monitors off
        '';
      };
    in
    {
      environment.systemPackages = [
        lock
      ];

      # lock on idle
      custom.programs = {
        # disable suspend and lockscreen if host doesn't lock
        noctalia.settingsReducers = lib.mkIf (!config.custom.lock.enable) [
          (
            prev:
            lib.recursiveUpdate prev {
              idle = {
                lockTimeout = 0;
                suspendTimeout = 0;
              };
            }
          )
        ];

        hyprland.settings = {
          bind = [ "$mod_SHIFT_CTRL, x, exec, ${lib.getExe lock}" ];

          # handle laptop lid
          bindl = lib.mkIf isLaptop [ ",switch:Lid Switch, exec, ${lib.getExe lock}" ];
        };

        niri.settings = {
          binds = {
            "Mod+Shift+Ctrl+x".spawn = [
              (lib.getExe lock)
            ];
          };

          switch-events = {
            lid-open = {
              spawn = lib.getExe lock;
            };
          };
        };

        mango.settings = {
          bind = [ "$mod+SHIFT+CTRL, x, spawn, ${lib.getExe lock}" ];
        };
      };
    };
}
