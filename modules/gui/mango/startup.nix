{ lib, ... }:
{
  flake.nixosModules.wm =
    { config, pkgs, ... }:
    let
      monitorForWorkspace =
        wksp:
        (
          config.custom.hardware.monitors
          # default to first monitor if not found
          |> lib.findFirst (mon: lib.elem wksp mon.workspaces) (config.custom.hardware.monitors.elemAt 0)
        ).name;
    in
    {
      systemd.user.targets = {
        # ly -> mango -> noctalia-shell etc
        mango-session = {
          unitConfig = {
            Description = "mango compositor session";
            BindsTo = [ "graphical-session.target" ];
            # start the other services here after the WM has already started (push vs pull)
            Wants = [ "graphical-session-pre.target" ] ++ config.custom.startupServices;
            Before = config.custom.startupServices;
            After = [ "graphical-session-pre.target" ];
          };
        };
      };

      custom.programs = {
        mango.settings = {
          # systemd activation blurb, similar as hyprland
          exec-once = [
            "${lib.getExe' pkgs.dbus "dbus-update-activation-environment"} --systemd DISPLAY WAYLAND_DISPLAY XDG_CURRENT_DESKTOP && systemctl --user restart mango-session.target"
          ]
          ++ (
            config.custom.startup
            |> lib.filter (startup: startup.enable)
            |> map (startup: lib.concatStringsSep " " startup.spawn)
          );

          # create rules to open the programs on the initial workspaces
          windowrule =
            config.custom.startup
            |> lib.filter (startup: startup.enable)
            |> lib.filter (startup: startup.app-id != null || startup.title != null)
            |> map (
              startup:
              lib.concatStringsSep "," (
                [
                  # there are only 9 tags
                  "tags:${
                    toString (if startup.workspace == 10 then 8 else startup.workspace)
                  },monitor:${monitorForWorkspace startup.workspace}"
                ]
                ++ (lib.optional (startup.app-id != null) "appid:${startup.app-id}")
                ++ (lib.optional (startup.title != null) "title:${startup.title}")
              )
            );
        };
      };
    };
}
