{ lib, ... }:
{
  flake.nixosModules.wm =
    { config, pkgs, ... }:
    {
      # generate startup rules, god i hate having to use rules for startup
      custom.programs.niri.settings = lib.mkMerge (
        (
          config.custom.startup
          |> lib.filter (startup: startup.enable)
          |> map (startup: {
            spawn-at-startup = [ startup.spawn ];
            config = # kdl
              lib.mkIf (startup.app-id != null || startup.title != null) ''
                window-rule {
                    match ${lib.optionalString (startup.app-id != null) ''app-id="^${startup.app-id}$"''} ${
                      lib.optionalString (startup.title != null) ''title="^${startup.title}$"''
                    } at-startup=true
                    open-on-workspace "${toString startup.workspace}"
                    ${startup.niriArgs}
                }
              '';
          })
        )
        ++ [
          # focus default workspace for each monitor
          {
            spawn-at-startup = lib.mkAfter (
              map (mon: [
                "niri"
                "msg"
                "action"
                "focus-workspace"
                "${toString mon.defaultWorkspace}"
              ]) (lib.reverseList config.custom.hardware.monitors)
            );
          }
        ]
      );

      systemd.user = {
        # ly -> niri.service -> niri-session.service -> noctalia-shell.service etc
        targets.niri-session = {
          wantedBy = [ "niri.service" ];

          unitConfig = {
            Description = "Niri compositor session";
            BindsTo = [ "niri.service" ];
            # start the other services here after the WM has already started (push vs pull)
            Wants = [ "niri.service" ] ++ config.custom.startupServices;
            Before = config.custom.startupServices;
            After = [ "niri.service" ];
          };
        };

        # listen to events from niri, done as a service so it will restart from nixos-rebuild
        services.niri-ipc = {
          wantedBy = [ "graphical-session.target" ];

          unitConfig = {
            Description = "Custom niri-ipc from dotfiles-rs";
            PartOf = [ "graphical-session.target" ];
          };

          serviceConfig = {
            ExecStart = lib.getExe' pkgs.custom.dotfiles-rs "niri-ipc";
            Restart = "on-failure";
          };
        };
      };

      # start after WM initializes
      custom.startupServices = [ "niri-ipc.service" ];
    };
}
