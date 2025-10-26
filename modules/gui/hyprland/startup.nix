{
  flake.nixosModules.wm =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib)
        concatStringsSep
        getExe'
        mkIf
        optionalString
        ;
    in
    {
      custom.autologinCommand = mkIf (config.custom.wm == "hyprland") "Hyprland";

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
            rules = optionalString (workspace != null) "[workspace ${toString workspace} silent]";
            exec = concatStringsSep " " spawn;
          in
          if enable then "${rules} ${exec}" else ""
        ) config.custom.startup;
      };

      systemd.user.services = {
        # listen to events from hyprland, done as a service so it will restart from nixos-rebuild
        hypr-ipc = {
          wantedBy = [ "hyprland-session.target" ];

          unitConfig = {
            ConditionEnvironment = "WAYLAND_DISPLAY";
            Description = "Custom hypr-ipc from dotfiles-rs";
            After = [ "hyprland-session.target" ];
            PartOf = [ "hyprland-session.target" ];
          };

          serviceConfig = {
            ExecStart = "${getExe' pkgs.custom.dotfiles-rs "hypr-ipc"}";
            Restart = "on-failure";
          };
        };
      };
    };
}
