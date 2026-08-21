{
  tags = [ "wm" ];

  config =
    { config, lib, ... }:
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
          ++ config.custom.wm.startup
          ++
            # focus default workspace for each monitor
            (map (mon: {
              spawn = "hyprctl dispatch hl.dsp.focus({ workspace = ${toString mon.defaultWorkspace} })";
            }) (lib.reverseList config.custom.hardware.monitors))
        )
        |> map mkStartupCmd
        |> lib.concatLines;

      systemd.user = {
        # listen to events from hyprland, done as a service so it will restart from nixos-rebuild
        services.hypr-ipc = {
          wantedBy = [ "graphical-session.target" ];

          unitConfig = {
            ConditionEnvironment = "WAYLAND_DISPLAY";
            Description = "Custom hypr-ipc from dotfiles-rs";
            After = [ "graphical-session.target" ];
            PartOf = [ "graphical-session.target" ];
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
      custom.wm.startupServices = [ "hypr-ipc.service" ];
    };
}
