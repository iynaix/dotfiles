{
  config,
  lib,
  ...
}:
let
  inherit (lib)
    mkAfter
    mkIf
    mkMerge
    optionalAttrs
    reverseList
    ;
in
mkIf (config.custom.wm == "niri") {
  custom = {
    autologinCommand = "niri-session > /tmp/niri-session.log 2>&1";
  };

  # generate startup rules, god i hate having to use rules for startup
  programs.niri.settings = mkMerge (
    (map (
      startup:
      (mkIf startup.enable {
        spawn-at-startup = [ { command = startup.spawn; } ];
        window-rules = mkIf (startup.workspace != null) [
          (
            {
              matches = [
                (
                  {
                    at-startup = true;
                  }
                  // optionalAttrs (startup.app-id != null) { app-id = "^${startup.app-id}$"; }
                  // optionalAttrs (startup.title != null) { title = "^${startup.title}$"; }
                )
              ];
              open-on-workspace = "W${toString startup.workspace}";
            }
            # any extra args
            // startup.niriArgs
          )
        ];
      })
    ) config.custom.startup)
    ++ [
      # focus default workspace for each monitor
      {
        spawn-at-startup = mkAfter (
          map (mon: {
            command = [
              "niri"
              "msg"
              "action"
              "focus-workspace"
              "W${toString mon.defaultWorkspace}"
            ];
          }) (reverseList config.custom.monitors)
        );
      }
    ]
  );

  # start a separate swww service in a different namespace for niri backdrop
  systemd.user.services = {
    swww-backdrop = {
      Install = {
        WantedBy = [ config.wayland.systemd.target ];
      };

      Unit = {
        ConditionEnvironment = "WAYLAND_DISPLAY";
        Description = "swww-daemon-backdrop";
        After = [ config.wayland.systemd.target ];
        PartOf = [ config.wayland.systemd.target ];
      };

      Service = {
        ExecStart = "${lib.getExe' config.services.swww.package "swww-daemon"} --namespace backdrop";
        Restart = "always";
        RestartSec = 10;
      };
    };

    # wallpaper needs both swww daemons running
    wallpaper = {
      Unit = {
        After = [ "swww-backdrop.service" ];
        Requires = [ "swww-backdrop.service" ];
      };
    };
  };
}
