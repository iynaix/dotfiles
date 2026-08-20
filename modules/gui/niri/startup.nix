{ lib, ... }:
{
  flake.modules.nixos.wm =
    { config, pkgs, ... }:
    {
      # generate startup rules, god i hate having to use rules for startup
      custom.programs.niri.settings = lib.mkMerge (
        (
          config.custom.wm.startup
          |> lib.filter (startup: startup.enable)
          |> map (startup: {
            spawn-sh-at-startup = [ startup.spawn ];
            window-rules = lib.optional (startup.app-id != null || startup.title != null) (
              {
                matches = [
                  (
                    {
                      at-startup = true;
                    }
                    // (lib.optionalAttrs (startup.app-id != null) {
                      app-id = _: { custom = ''r#"${startup.app-id}"#''; };
                    })
                    // (lib.optionalAttrs (startup.title != null) {
                      title = _: { custom = ''r#"${startup.title}"#''; };
                    })
                  )
                ];
                open-on-workspace = toString startup.workspace;
              }
              // startup.niriArgs
            );
          })
        )
        ++ [
          # focus default workspace for each monitor
          {
            spawn-sh-at-startup = lib.mkAfter (
              map (mon: "sleep 0.5; niri msg action focus-workspace ${toString mon.defaultWorkspace}") (
                lib.reverseList config.custom.hardware.monitors
              )
            );
          }

          # resize the browsers after startup
          {
            spawn-sh-at-startup = lib.mkOrder 2000 [
              (lib.getExe (
                pkgs.writeShellApplication {
                  name = "niri-initial";
                  text = ''
                    sleep 5; niri-resize-workspace 1
                  '';
                }
              ))
            ];
          }
        ]
      );

      systemd.user = {
        # listen to events from niri, done as a service so it will restart from nixos-rebuild
        services.niri-ipc = {
          wantedBy = [ "graphical-session.target" ];

          unitConfig = {
            Description = "Custom niri-ipc from dotfiles-rs";
            PartOf = [ "graphical-session.target" ];
          };

          serviceConfig = {
            ExecStart = lib.getExe' config.custom.programs.dotfiles-rs "niri-ipc";
            RestartSec = 1;
            Restart = "on-failure";
          };

          restartTriggers = [
            config.programs.niri.package
          ];
        };
      };

      # start after WM initializes
      custom.wm.startupServices = [ "niri-ipc.service" ];
    };
}
