{
  config,
  inputs,
  isNixOS,
  lib,
  pkgs,
  ...
}:
let
  focal = inputs.focal.packages.${pkgs.system}.default.override {
    hyprland = config.wayland.windowManager.hyprland.package;
    rofi-wayland = config.programs.rofi.package;
    ocr = true;
  };
  signum = 1;
in
lib.mkIf config.custom.hyprland.enable {
  home.packages =
    (with pkgs; [
      swappy
      wf-recorder
    ])
    ++ lib.optionals isNixOS [ focal ];

  # swappy conf
  xdg.configFile."swappy/config".text = lib.generators.toINI { } {
    default = {
      save_dir = "${config.xdg.userDirs.pictures}/Screenshots";
      save_filename_format = "%Y-%m-%dT%H:%M:%S%z.png";
      show_panel = false;
      line_size = 5;
      text_size = 20;
      text_font = "sans-serif";
      paint_mode = "brush";
      early_exit = false;
      fill_shape = false;
    };
  };

  # add focal module to waybar
  custom.waybar = {
    config = {
      "custom/focal" = {
        exec = ''focal-waybar --signal ${toString signum} --recording "󰑋" --interval 2'';
        format = "{}";
        # hide-empty-text = true;
        # return-type = "json";
        signal = signum;
        on-click = "focal video --stop";
        interval = "once";
      };

      modules-left = lib.mkAfter [ "custom/focal" ];
    };

    extraCss = ''
      #custom-focal {
        font-size: 24px;
      }
    '';
  };

  wayland.windowManager.hyprland.settings = {
    bind = [
      "$mod, backslash, exec, focal image --area selection --no-notify --no-save --no-rounded-windows"
      "$mod_SHIFT, backslash, exec, focal image --edit swappy --rofi --no-rounded-windows"
      "$mod_CTRL, backslash, exec, focal image --area selection --ocr"
      ''ALT, backslash, exec, focal-waybar --toggle --signal ${toString signum} --recording "󰑋" --rofi --no-rounded-windows''
    ];
  };
}
