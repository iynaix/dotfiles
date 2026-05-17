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
        runtimeInputs = [ pkgs.noctalia-shell ];
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

        # handle laptop lid on the WMs
        hyprland.luaText = /* lua */ ''
          hl.bind(mod .. " + SHIFT + CTRL + x", hl.dsp.exec_cmd("${lib.getExe lock}"))

          hl.bind("switch:Lid Switch", hl.dsp.exec_cmd("${lib.getExe lock}"), { locked = true })
        '';

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
