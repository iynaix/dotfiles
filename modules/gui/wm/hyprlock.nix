{ lib, ... }:
let
  inherit (lib)
    mkEnableOption
    mkIf
    ;
in
{
  perSystem =
    { pkgs, ... }:
    {
      packages.lock = pkgs.writeShellApplication {
        name = "lock";
        runtimeInputs = with pkgs; [
          procps
          hyprlock
        ];
        text = # sh
          "pidof hyprlock || hyprlock";
      };
    };

  flake.nixosModules.core =
    { isLaptop, ... }:
    {
      options.custom = {
        lock.enable = mkEnableOption "screen locking of host" // {
          default = isLaptop;
        };
      };
    };

  flake.nixosModules.wm =
    {
      config,
      isLaptop,
      pkgs,
      self,
      ...
    }:
    mkIf config.custom.lock.enable {
      programs.hyprlock.enable = true;

      environment.systemPackages = [ self.packages.${pkgs.stdenv.hostPlatform.system}.lock ];

      # lock on idle
      custom.programs = {
        hypridle = {
          settings = {
            general = {
              lock_cmd = "lock";
            };

            listener = [
              {
                timeout = 5 * 60;
                on-timeout = "lock";
              }
            ];
          };
        };

        hyprland.settings =
          let
            lockOrDpms = if config.custom.lock.enable then "exec, lock" else "dpms, off";
          in
          {
            bind = [ "$mod_SHIFT_CTRL, x, ${lockOrDpms}" ];

            # handle laptop lid
            bindl = mkIf isLaptop [ ",switch:Lid Switch, ${lockOrDpms}" ];
          };

        niri.settings =
          let
            lockOrDpms =
              if config.custom.lock.enable then
                "lock"
              else
                # lid-open actions only support spawn for now
                [
                  "niri"
                  "msg"
                  "action"
                  "power-off-monitors"
                ];
          in
          {
            binds = {
              "Mod+Shift+Ctrl+x".action.spawn = lockOrDpms;
            };

            switch-events = {
              lid-open.action.spawn = lockOrDpms;
            };
          };

        # TODO: mango doesn't support switch events yet?
        mango.settings =
          let
            lockOrDpms =
              if config.custom.lock.enable then
                "spawn, lock"
              else
                # TODO: support dpms off with wlr-dpms?
                "spawn, lock";
          in
          {
            bind = [ "$mod+SHIFT+CTRL, x, ${lockOrDpms}" ];
          };

        wallust.templates."hyprlock.conf" = {
          text =
            let
              rgba = colorname: alpha: "rgba({{ ${colorname} | rgb }},${toString alpha})";
            in
            self.lib.generators.toHyprconf {
              attrs = {
                general = {
                  disable_loading_bar = false;
                  grace = 0;
                  hide_cursor = false;
                };

                background = map (mon: {
                  monitor = "${mon.name}";
                  # add trailing comment with monitor name for wallpaper to replace later
                  path = "/tmp/swww__${mon.name}.webp";
                  color = "${rgba "background" 1}";
                }) config.custom.hardware.monitors;

                input-field = {
                  monitor = "";
                  size = "300, 50";
                  outline_thickness = 2;
                  dots_size = 0.33;
                  dots_spacing = 0.15;
                  dots_center = true;
                  outer_color = "${rgba "background" 0.8}";
                  inner_color = "${rgba "foreground" 0.9}";
                  font_color = "${rgba "background" 0.8}";
                  fade_on_empty = false;
                  placeholder_text = "";
                  hide_input = false;

                  position = "0, -20";
                  halign = "center";
                  valign = "center";
                };

                label = [
                  {
                    monitor = "";
                    text = ''cmd[update:1000] echo "<b><big>$(date +"%H:%M")</big></b>"'';
                    color = "${rgba "foreground" 1}";
                    font_size = 150;
                    font_family = "${config.custom.fonts.regular}";

                    # shadow makes it more readable on light backgrounds
                    shadow_passes = 1;
                    shadow_size = 4;

                    position = "0, 190";
                    halign = "center";
                    valign = "center";
                  }
                  {
                    monitor = "";
                    text = ''cmd[update:1000] echo "<b><big>$(date +"%A, %B %-d")</big></b>"'';
                    color = "${rgba "foreground" 1}";
                    font_size = 40;
                    font_family = "${config.custom.fonts.regular}";

                    # shadow makes it more readable on light backgrounds
                    shadow_passes = 1;
                    shadow_size = 2;

                    position = "0, 60";
                    halign = "center";
                    valign = "center";
                  }
                ];
              };
            };
          target = "${config.hj.xdg.config.directory}/hypr/hyprlock.conf";
        };
      };
    };
}
