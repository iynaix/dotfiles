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
    {
      config,
      pkgs,
      ...
    }:
    {
      custom.autologinCommand = mkIf (config.custom.wm == "niri") "niri-session";

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

      systemd.user.services = {
        # listen to events from niri, done as a service so it will restart from nixos-rebuild
        niri-ipc = {
          wantedBy = [ "graphical-session.target" ];

          unitConfig = {
            ConditionEnvironment = "WAYLAND_DISPLAY";
            Description = "Custom niri-ipc from dotfiles-rs";
            After = [ "niri.service" ];
            PartOf = [ "graphical-session.target" ];
          };

          serviceConfig = {
            ExecStart = getExe' pkgs.custom.dotfiles-rs "niri-ipc";
            Restart = "on-failure";
          };
        };
      };
    };
}
