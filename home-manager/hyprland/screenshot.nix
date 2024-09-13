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
  focal-waybar = pkgs.writeShellApplication {
    name = "focal-waybar";
    runtimeInputs = with pkgs; [
      procps
      focal
    ];
    text = ''
      lock="$XDG_RUNTIME_DIR/focal.lock"

      update_waybar() {
          echo "$1"
          pkill -SIGRTMIN+${toString signum} .waybar-wrapped
      }

      if [[ "$*" == *"--toggle"* ]]; then
          if [ -f "$lock" ]; then
              # stop the video
              focal --video --rofi

              update_waybar ""
          else
              # start recording
              update_waybar "󰑋"

              focal --video --rofi
          fi
      else
          if [ -f "$lock" ]; then
              update_waybar "󰑋"
          else
              update_waybar ""
          fi
      fi
    '';
  };

in
lib.mkIf config.custom.hyprland.enable {
  home.packages = lib.mkIf isNixOS (
    [ focal ]
    ++ (with pkgs; [
      swappy
      wf-recorder
    ])
  );

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

  custom.shell.packages = {
    inherit focal-waybar;
  };

  # add focal module to waybar
  custom.waybar = {
    config = {
      "custom/focal" = {
        exec = "focal-waybar";
        format = "{}";
        # hide-empty-text = true;
        # return-type = "json";
        signal = signum;
        on-click = "focal --rofi --video";
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
      "$mod, backslash, exec, focal --area selection --no-notify --no-save"
      "$mod_SHIFT, backslash, exec, focal --edit swappy --rofi"
      "$mod_CTRL, backslash, exec, focal --area selection --ocr"
      "ALT, backslash, exec, ${lib.getExe pkgs.custom.shell.focal-waybar} --toggle"
    ];
  };
}
