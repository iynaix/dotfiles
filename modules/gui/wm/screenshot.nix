{
  flake.nixosModules.wm =
    {
      config,
      inputs,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib) getExe' mkAfter;
      focal = inputs.focal.packages.${pkgs.stdenv.hostPlatform.system}.default;
    in
    {
      environment.systemPackages = [
        pkgs.swappy
        pkgs.wf-recorder
        focal
      ];

      # swappy conf
      hj.xdg.config.files."swappy/config".text = lib.generators.toINI { } {
        default = {
          save_dir = "${config.hj.directory}/Pictures/Screenshots";
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

      custom.programs = {
        hyprland.settings = {
          bind = [
            "$mod, backslash, exec, focal image --area selection --no-notify --no-save --no-rounded-windows"
            "$mod_SHIFT, backslash, exec, focal image --edit swappy --rofi --no-rounded-windows"
            "$mod_CTRL, backslash, exec, focal image --area selection --ocr"
            "ALT, backslash, exec, focal video --rofi --no-rounded-windows"
          ];
        };

        niri.settings = {
          binds = {
            "Mod+backslash".action.screenshot = {
              show-pointer = false;
            };
            "Mod+Shift+backslash".action.spawn = [
              "focal"
              "image"
              # "--edit"
              # "swappy"
              "--rofi"
            ];
            # "Mod+Ctrl+backslash".action.spawn = [
            #   "focal"
            #   "image"
            #   "--area"
            #   "selection"
            #   "--ocr"
            # ];
            "Alt+backslash".action.spawn = [
              "focal"
              "video"
              "--rofi"
            ];
          };
        };

        mango.settings = {
          bind = [
            "$mod, backslash, spawn, focal image --area selection --no-notify --no-save --no-rounded-windows"
            "$mod+SHIFT, backslash, spawn, focal image --edit swappy --rofi --no-rounded-windows"
            "$mod+CTRL, backslash, spawn, focal image --area selection --ocr"
            "ALT, backslash, spawn, focal video --rofi --no-rounded-windows"
          ];
        };

        # add focal module to waybar
        waybar = {
          config = {
            "custom/focal" = {
              exec = # sh
                ''${getExe' focal "focal-waybar"} --recording "󰑋"'';
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
      };
    };
}
