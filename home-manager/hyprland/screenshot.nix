{
  config,
  isNixOS,
  lib,
  pkgs,
  ...
}: let
  screenshotDir = "${config.xdg.userDirs.pictures}/Screenshots";
  iso8601 = "%Y-%m-%dT%H:%M:%S%z";
  # screenshot with rofi options to preselect
  hypr-screenshot = pkgs.writeShellApplication {
    name = "hypr-screenshot";
    runtimeInputs = with pkgs; [
      grimblast
      libnotify
      swappy
      rofi
    ];
    text = lib.replaceStrings ["@@outputPath@@"] ["${screenshotDir}/$(date +${iso8601}).png"] (builtins.readFile ./screenshot.sh);
  };
  # run ocr on selected area and copy to clipboard
  hypr-ocr = pkgs.writeShellApplication {
    name = "hypr-ocr";
    runtimeInputs = [pkgs.tesseract5];
    text = ''
      img="${screenshotDir}/ocr.png"

      grimblast save area "$img"
      teserract5 "$img" - | wl-copy
      rm "$img"
      notify-send "$(wl-paste)"
    '';
  };
in
  lib.mkIf config.wayland.windowManager.hyprland.enable {
    home.packages =
      [
        hypr-ocr
        hypr-screenshot
      ]
      ++ (lib.optionals isNixOS (with pkgs; [
        grimblast
        swappy
      ]));

    # swappy conf
    xdg.configFile."swappy/config".text = ''
      [Default]
      save_dir=${screenshotDir}
      save_filename_format=${iso8601}.png
      show_panel=false
      line_size=5
      text_size=20
      text_font=sans-serif
      paint_mode=brush
      early_exit=false
      fill_shape=false
    '';

    wayland.windowManager.hyprland.settings = {
      bind = [
        "$mod, backslash, exec, grimblast --notify copy area"
        "$mod_SHIFT, backslash, exec, hypr-screenshot"
        "$mod_CTRL, backslash, exec, hypr-ocr"
      ];
    };
  }
