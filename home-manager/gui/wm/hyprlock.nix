{
  config,
  isLaptop,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) getExe mkIf mkMerge;
  lockPkg = pkgs.writeShellApplication {
    name = "lock";
    runtimeInputs = [
      pkgs.procps
      config.programs.hyprlock.package
    ];
    text = # sh
      "pidof hyprlock || hyprlock";
  };
  lockCmd = getExe lockPkg;
in
mkMerge [
  (mkIf config.custom.lock.enable {
    programs.hyprlock.enable = true;

    custom.shell.packages = {
      lock = lockPkg;
    };

    home.packages = [ config.custom.shell.packages.lock ];

    # lock on idle
    services.hypridle = {
      settings = {
        general = {
          lock_cmd = lockCmd;
        };

        listener = [
          {
            timeout = 5 * 60;
            on-timeout = lockCmd;
          }
        ];
      };
    };

    custom.wallust.templates."hyprlock.conf" = {
      text =
        let
          rgba = colorname: alpha: "rgba({{ ${colorname} | rgb }},${toString alpha})";
        in
        lib.hm.generators.toHyprconf {
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
            }) config.custom.monitors;

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
      target = "${config.xdg.configHome}/hypr/hyprlock.conf";
    };
  })

  # settings for hyprland
  (mkIf (config.custom.wm == "hyprland") {
    wayland.windowManager.hyprland.settings =
      let
        lockOrDpms = if config.custom.lock.enable then "exec, ${lockCmd}" else "dpms, off";
      in
      {
        bind = [ "$mod_SHIFT_CTRL, x, ${lockOrDpms}" ];

        # handle laptop lid
        bindl = mkIf isLaptop [ ",switch:Lid Switch, ${lockOrDpms}" ];
      };
  })

  # settings for niri
  (mkIf (config.custom.wm == "niri") {
    programs.niri.settings =
      let
        lockOrDpms =
          if config.custom.lock.enable then
            lockCmd
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
          "Mod+Shift+x".action.spawn = lockOrDpms;
        };

        switch-events = mkIf isLaptop {
          lid-open.action.spawn = lockOrDpms;
        };
      };
  })
]
