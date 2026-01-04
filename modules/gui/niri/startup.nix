{ lib, ... }:
let
  inherit (lib)
    getExe'
    mkAfter
    mkIf
    mkMerge
    optionalString
    reverseList
    ;
in
{
  flake.nixosModules.wm =
    { config, pkgs, ... }:
    {
      # generate startup rules, god i hate having to use rules for startup
      custom.programs.niri.settings = mkMerge (
        (map (
          startup:
          (mkIf startup.enable {
            spawn-at-startup = [ startup.spawn ];
            config = /* kdl */ ''
              window-rule {
                  match ${optionalString (startup.app-id != null) ''app-id="^${startup.app-id}$"''} ${
                    optionalString (startup.title != null) ''title="^${startup.title}$"''
                  } at-startup=true
                  open-on-workspace "${toString startup.workspace}"
                  ${startup.niriArgs}
              }
            '';
          })
        ) config.custom.startup)
        ++ [
          # focus default workspace for each monitor
          {
            spawn-at-startup = mkAfter (
              map (mon: [
                "niri"
                "msg"
                "action"
                "focus-workspace"
                "${toString mon.defaultWorkspace}"
              ]) (reverseList config.custom.hardware.monitors)
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
            ExecStart = getExe' pkgs.custom.dotfiles-rs "niri-ipc";
            Restart = "on-failure";
          };
        };
      };

      # start after WM initializes
      custom.startupServices = [ "niri-ipc.service" ];
    };
}
