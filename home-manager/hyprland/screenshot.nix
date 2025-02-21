{
  config,
  inputs,
  isNixOS,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkAfter mkIf optionals;
  focal = inputs.focal.packages.${pkgs.system}.default.override {
    hyprland = config.wayland.windowManager.hyprland.package;
    rofi-wayland = config.programs.rofi.package;
    ocr = true;
  };
in
mkIf config.custom.hyprland.enable {
  home.packages =
    (with pkgs; [
      swappy
      wf-recorder
    ])
    ++ optionals isNixOS [ focal ];

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

  # add focal module to waybar (don't use for otg specialisation)
  custom.waybar = mkIf (config.specialisation != "otg") {
    config = {
      "custom/focal" = {
        exec = # sh
          ''focal-waybar --recording "󰑋"'';
        format = "{}";
        # hide-empty-text = true;
        # return-type = "json";
        on-click = "focal video --stop";
        interval = 2; # poll every 2s
      };

      modules-left = mkAfter [ "custom/focal" ];
    };

    extraCss = # css
      ''
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
      ''ALT, backslash, exec, focal video --rofi --no-rounded-windows''
    ];
  };
}
