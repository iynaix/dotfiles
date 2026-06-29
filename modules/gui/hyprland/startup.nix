{ lib, ... }:
{
  flake.modules.nixos.wm =
    { config, ... }:
    {
      custom.programs.hyprland.settings =
        let
          toLua = lib.generators.toLua { };
          mkStartupCmd =
            {
              enable ? true,
              spawn,
              workspace ? null,
              hyprlandArgs ? { },
              ...
            }:
            let
              wksp = lib.optionalAttrs (workspace != null) {
                workspace = "${toString workspace} silent";
              };
            in
            lib.optionalString enable ''
              hl.on("hyprland.start", function ()
                hl.exec_cmd("${spawn}", ${toLua wksp})
              end)

              ${lib.optionalString (hyprlandArgs != { }) ''
                hl.window_rule(${toLua ({ match = hyprlandArgs; } // wksp)})
              ''}
            '';
        in
        (
          [
            # stop fucking with my cursors
            { spawn = "hyprctl setcursor ${"Simp1e-Tokyo-Night"} ${toString 28}"; }
          ]
          ++ config.custom.startup
          ++
            # focus default workspace for each monitor
            (map (mon: {
              spawn = "hyprctl dispatch hl.dsp.focus({ workspace = ${toString mon.defaultWorkspace} })";
            }) (lib.reverseList config.custom.hardware.monitors))
        )
        |> map mkStartupCmd
        |> lib.concatLines;

      systemd.user = {
        # ly -> hyprland-start -> exec-once hyprland-session.service -> startupServices
        # so the environment will be properly set
        targets.hyprland-session = {
          unitConfig = {
            Description = "Hyprland compositor session";
            BindsTo = [ "graphical-session.target" ];
            # start the other services here after the WM has already started (push vs pull)
            Wants = [ "graphical-session-pre.target" ] ++ config.custom.startupServices;
            Before = config.custom.startupServices;
            After = [ "graphical-session-pre.target" ];
          };
        };

        # listen to events from hyprland, done as a service so it will restart from nixos-rebuild
        services.hypr-ipc = {
          wantedBy = [ "hyprland-session.target" ];

          unitConfig = {
            ConditionEnvironment = "WAYLAND_DISPLAY";
            Description = "Custom hypr-ipc from dotfiles-rs";
            After = [ "hyprland-session.target" ];
            PartOf = [ "hyprland-session.target" ];
          };

          serviceConfig = {
            ExecStart = "${lib.getExe' config.custom.programs.dotfiles-rs "hypr-ipc"}";
            RestartSec = 1;
            Restart = "on-failure";
          };

          restartTriggers = [
            config.programs.hyprland.package
          ];
        };
      };

      # start after WM initializes
      custom.startupServices = [ "hypr-ipc.service" ];
    };
}
