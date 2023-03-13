{ pkgs, config, host, user, lib, ... }:
let
  displayCfg = config.iynaix.displays;
  kitty = "${pkgs.kitty}/bin/kitty";
  nmtui = "${pkgs.networkmanager}/bin/nmtui";
in
{
  config = lib.mkIf config.iynaix.bspwm.enable {
    home-manager.users.${user} = {
      services.polybar = {
        enable = config.iynaix.bspwm.enable;
        package = lib.mkDefault (pkgs.polybar.override {
          pulseSupport = true;
        });
        config = {
          colors = with config.iynaix.xrdb; {
            background = background;
            foreground = foreground;
            focused = color8;
            urgent = color5;
            disconnected = color1;
            empty = color0;
          };
          # BARS
          "bar/base" = {
            width = "100%";
            height = 30;
            offset-x = 0;
            offset-y = 0;

            background = ''''${colors.background}'';
            foreground = ''''${colors.foreground}'';

            underline-size = 2;
            underline-color = ''''${colors.foreground}'';

            padding-left = 0;
            padding-right = 0;
            module-margin-left = 0;
            module-margin-right = 0;

            font-0 = "Noto Sans:size=10;0";
            font-1 = "${config.iynaix.font.monospace}:size=10;1";

            # tray-position = "right";
            # tray-padding = 2;
            # tray-background = "#66333333";

            wm-restack = "bspwm";
          };
          "bar/${host}" = {
            "inherit" = "bar/base";
            # modules-right = "battery volume mpd date";
            monitor = "${displayCfg.monitor1}";

            modules-left = "bspwm_mode";
            modules-center = "bspwm";
            modules-right = "wlan volume backlight battery date";
          };

          # MODULES

          "module/title" = { type = "internal/xwindow"; };
          "module/bspwm" = {
            type = "internal/bspwm";

            pin-workspaces = true;
            enable-click = true;
            enable-scroll = false;

            # ws-icon-0 = "1;";
            # ws-icon-1 = "2;";
            # ws-icon-2 = "3;";
            # ws-icon-3 = "4;";
            # ws-icon-4 = "5;";
            # ws-icon-5 = "6;";
            # ws-icon-6 = "7;";
            # ws-icon-7 = "8;";
            # ws-icon-8 = "9;";
            # ws-icon-9 = "10;";

            # ws-icon-0 = "1;";
            # ws-icon-1 = "2;";
            # ws-icon-2 = "3;";
            # ws-icon-3 = "4;";
            # ws-icon-4 = "5;";
            # ws-icon-5 = "6;";
            # ws-icon-6 = "7;";
            # ws-icon-7 = "8;";
            # ws-icon-8 = "9;";
            # ws-icon-9 = "10;";

            format = "<label-state>";

            # label-focused = "";
            label-focused-background = ''''${colors.focused}'';
            label-focused-underline = ''''${colors.focused}'';
            label-focused-padding = 4;

            # label-occupied = "";
            label-occupied-padding = 4;

            # label-urgent = "%icon%";
            label-urgent-background = ''''${colors.urgent}'';
            label-urgent-underline = ''''${colors.urgent}'';
            label-urgent-padding = 4;

            # label-empty = "%icon%";
            label-empty-foreground = ''''${colors.empty}'';
            label-empty-padding = 4;
          };

          "module/bspwm_mode" = {
            type = "internal/bspwm";

            format = "<label-mode>";

            label-monocle = "";
            label-monocle-padding = 4;
            label-fullscreen = "";
            label-fullscreen-padding = 4;
            label-floating = "";
            label-floating-padding = 4;
            # label-pseudotiled = "P";
            label-locked = "";
            label-locked-padding = 4;
            label-locked-foreground = "#bd2c40";
            label-sticky = "";
            label-sticky-padding = 4;
            label-sticky-foreground = "#fba922";
            # label-private = "";
            # label-private-foreground = "#bd2c40";
            # label-marked = "M";
          };
          "module/date" = {
            type = "internal/date";

            # Seconds to sleep between updates
            interval = 1;

            # See "man date" for details on how to format the date string
            # NOTE: if you want to use syntax tags here you need to use %%{...}
            date = "%a %b %d";

            # Optional time format
            time = "%H:%M";

            # if `date-alt` or `time-alt` is defined, clicking
            # the module will toggle between formats
            # date-alt = "%A, %d %B %Y";
            time-alt = "%a %b %d";

            # label = "%date% %time%";
            label = "%time%";
            format = "  <label>";
            format-padding = 3;
          };
          "module/battery" = {
            type = "internal/battery";

            full-at = 99;

            battery = "BAT0";
            adapter = "AC0";

            poll-interval = 5;

            format-charging = "<animation-charging>    <label-charging>";
            format-discharging = "<ramp-capacity>    <label-discharging>";
            format-full = "<ramp-capacity>    <label-full>";
            label-charging = "%percentage%";
            label-discharging = "%percentage%";
            label-full = "%percentage%";
            format-charging-padding = 3;
            format-discharging-padding = 3;
            format-full-padding = 3;

            ramp-capacity-0 = "";
            ramp-capacity-1 = "";
            ramp-capacity-2 = "";
            ramp-capacity-3 = "";
            ramp-capacity-4 = "";

            animation-charging-0 = "";
            animation-charging-1 = "";
            animation-charging-2 = "";
            animation-charging-3 = "";
            animation-charging-4 = "";
            animation-charging-framerate = 750;
          };
          "module/backlight" = {
            type = "internal/backlight";

            card = "intel_backlight";
            enable-scroll = true;

            format = "<ramp>  <label>";
            label = "%percentage%";

            ramp-0 = "";
            ramp-1 = "󰃝";
            ramp-2 = "󰃟";
            ramp-3 = "󰃞";
          };
          "module/volume" = {
            type = "internal/pulseaudio";

            format-volume = "<ramp-volume>  <label-volume>";
            format-muted = "<label-muted>  0";
            label-volume = "%percentage%";
            label-muted = "";
            format-volume-padding = 3;
            format-muted-padding = 3;

            ramp-volume-0 = "";
            ramp-volume-1 = "";
            ramp-volume-2 = "";
            ramp-headphones-0 = "";
          };
          "module/mpd" = {
            type = "internal/mpd";

            host = "127.0.0.1";
            port = 6600;
            password = "";

            # Seconds to sleep between progressbar/song timer sync
            # Default: 1
            interval = 2;

            # Available tags:
            #   <label-song> (default)
            #   <label-time>
            #   <bar-progress>
            #   <toggle> - gets replaced with <icon-(pause|play)>
            #   <toggle-stop> - gets replaced with <icon-(stop|play)>
            #   <icon-random>
            #   <icon-repeat>
            #   <icon-repeatone>
            #   <icon-prev>
            #   <icon-stop>
            #   <icon-play>
            #   <icon-pause>
            #   <icon-next>
            #   <icon-seekb>
            #   <icon-seekf>
            format-online = " <label-song>";

            # Available tokens:
            #   %artist%
            #   %album%
            #   %date%
            #   %title%
            # Default: %artist% - %title%
            label-song = "%title%";
            format-online-padding = 3;
          };
          "module/lan" = {
            type = "internal/network";

            interface = "enp0s31f6";

            interval = 1;

            label-connected = "";
            label-disconnected = "";
            label-disconnected-foreground = ''''${colors.disconnected}'';
          };

          "module/wlan" = {
            type = "internal/network";

            interface = "wlp2s0";

            interval = 1;

            label-connected = "%{A:${kitty} ${nmtui}:}直  %essid%%{A}";
            label-disconnected = "%{A:${kitty} ${nmtui}:}睊%{A}";
            label-disconnected-foreground = ''''${colors.disconnected}'';
          };
        };
      };

      # home.file.".config/polybar/config".onChange = "systemctl --user restart";
    };
  };
}
