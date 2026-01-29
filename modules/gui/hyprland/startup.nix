{ lib, ... }:
{
  flake.nixosModules.wm =
    { config, ... }:
    {
      custom.programs.hyprland.settings = {
        exec-once = [
          # stop fucking with my cursors
          "hyprctl setcursor ${"Simp1e-Tokyo-Night"} ${toString 28}"
          "hyprctl dispatch workspace 1"
        ]
        # generate from startup options
        ++ map (
          {
            enable,
            spawn,
            workspace,
            ...
          }:
          let
            rules = lib.optionalString (workspace != null) "[workspace ${toString workspace} silent]";
            exec = lib.concatStringsSep " " spawn;
          in
          lib.optionalString enable "${rules} ${exec}"
        ) config.custom.startup;
      };

      systemd.user = {
        # ly -> hyprland-start -> exec-once hyprland-session.service -> noctalia-shell etc
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
        };
      };

      # start after WM initializes
      custom.startupServices = [ "hypr-ipc.service" ];
    };
}
