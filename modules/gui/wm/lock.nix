{ lib, ... }:
let
  inherit (lib) mkEnableOption mkIf;
in
{
  flake.nixosModules.core =
    { isLaptop, ... }:
    {
      options.custom = {
        lock.enable = mkEnableOption "screen locking of host" // {
          default = isLaptop;
        };
      };
    };

  flake.nixosModules.wm =
    {
      config,
      isLaptop,
      pkgs,
      ...
    }:
    mkIf config.custom.lock.enable {
      custom.shell.packages = {
        lock = {
          runtimeInputs = with pkgs; [
            noctalia-shell
          ];
          text = /* sh */ "noctalia-shell ipc call lockScreen lock";
        };
      };

      # lock on idle
      custom.programs = {
        hypridle = {
          settings = {
            general = {
              lock_cmd = "lock";
            };

            listener = [
              {
                timeout = 5 * 60;
                on-timeout = "lock";
              }
            ];
          };
        };

        hyprland.settings =
          let
            lockOrDpms = if config.custom.lock.enable then "exec, lock" else "dpms, off";
          in
          {
            bind = [ "$mod_SHIFT_CTRL, x, ${lockOrDpms}" ];

            # handle laptop lid
            bindl = mkIf isLaptop [ ",switch:Lid Switch, ${lockOrDpms}" ];
          };

        niri.settings =
          let
            lockOrDpms =
              if config.custom.lock.enable then
                [ "lock" ]
              else
                # lid-open actions only support spawn for now
                [
                  "niri"
                  "msg"
                  "action"
                  "power-off-monitors"
                ];
          in
          {
            binds = {
              "Mod+Shift+Ctrl+x".spawn = lockOrDpms;
            };

            /*
              switch-events = {
                lid-open.spawn = lockOrDpms;
              };
            */
          };

        # TODO: mango doesn't support switch events yet?
        mango.settings =
          let
            lockOrDpms =
              if config.custom.lock.enable then
                "spawn, lock"
              else
                # TODO: support dpms off with wlr-dpms?
                "spawn, lock";
          in
          {
            bind = [ "$mod+SHIFT+CTRL, x, ${lockOrDpms}" ];
          };
      };
    };
}
