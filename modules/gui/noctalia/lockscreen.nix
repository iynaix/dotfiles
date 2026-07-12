{ lib, ... }: {
  flake.modules.nixos.wm =
    { config, ... }:
    let
      inherit (config.custom.hardware) monitors;
      # widgets for each monitor are with hardcoded coordinates for each monitor :(
      # do some math to calculate widget positions for each monitor
      widgets =
        monitors
        |> map (
          mon:
          let
            mon_w = (if mon.isVertical then mon.height else mon.width) / mon.scale;
            mon_h = (if mon.isVertical then mon.width else mon.height) / mon.scale;
            cx = builtins.div mon_w 2.0;
            # NOTE: values calculated from layout on ultrawide (3440*1440)
            time_h = 384.0;
            date_h = 78.0;
            login_h = 120.0;
            time_cy_uw = 580.0;
            date_cy_uw = 758.0;
            login_cy_uw = 857.0;
            time_cy = (builtins.div time_cy_uw 1440.0) * mon_h;
            date_cy = time_cy + (date_cy_uw - time_cy_uw);
            login_cy = time_cy + (login_cy_uw - time_cy_uw);
          in
          {
            "lockscreen-widget-0000000000000001@${mon.name}" = {
              box_height = time_h;
              box_width = 640.0;
              inherit cx;
              cy = time_cy;
              output = mon.name;
              rotation = 0.0;
              type = "clock";

              settings = {
                background_opacity = 0.0;
                center_text = true;
                clock_style = "digital";
              };
            };

            "lockscreen-widget-0000000000000002@${mon.name}" = {
              box_height = date_h;
              box_width = 432.0;
              inherit cx;
              cy = date_cy;
              output = mon.name;
              rotation = 0.0;
              type = "clock";

              settings = {
                background_opacity = 0.0;
                center_text = true;
                color = "on_surface";
                format = "{:%A, %B %e}";
              };
            };

            "lockscreen-login-box@${mon.name}" = {
              box_height = login_h;
              box_width = 404;
              inherit cx;
              cy = login_cy;
              output = mon.name;
              rotation = 0.0;
              type = "login_box";

              settings = {
                background_color = "primary";
                background_opacity = 0.0;
                background_radius = 32.0;
                input_opacity = 1.0;
                input_radius = 0.0;
                show_caps_lock = true;
                show_keyboard_layout = false;
                show_login_button = false;
                show_password_hint = false;
              };
            };
          }
        )
        |> lib.mergeAttrsList;
    in
    {
      custom.programs.noctalia.settings = lib.mkAfter {
        lockscreen_widgets = {
          widget_order = lib.attrNames widgets;
          widget = widgets;
        };
      };
    };
}
