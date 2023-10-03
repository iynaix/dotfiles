{
  config,
  isNixOS,
  lib,
  pkgs,
  ...
}: let
  screenshotDir = "$HOME/Pictures/Screenshots";
  iso8601 = "%Y-%m-%dT%H:%M:%S%z";
  # screenshot with rofi options to preselect
  hypr-screenshot = pkgs.writeShellApplication {
    name = "hypr-screenshot";
    runtimeInputs = with pkgs; [
      grimblast
      libnotify
      swappy
      rofi-wayland
    ];
    text = ''
      mesg="Screenshots can be edited with swappy by using Alt+e"
      theme_str="
      * {
          width: 1000;
      }

      window {
          height: 625;
      }

      mainbox {
          children: [listview,message];
      }
      "

      _rofi() {
          rofi -dmenu -sep '|' -disable-history true -kb-custom-1 "Alt-e" -mesg "$mesg" -cycle true -lines 4 -theme-str "$theme_str" "$@"
      }

      choice=$(echo "Selection|Window|Monitor|All" | _rofi)
      # exit code 10 is alt-e
      exit_code=$?

      # first arg is the grimblast command
      screenshot() {
          img="${screenshotDir}/$(date +${iso8601}).png"
          if [ "$exit_code" -eq 10 ]; then
              grimblast save "$1" - | swappy -f - -o "$img"
              notify-send "Screenshot saved to $img" -i "$img"
          else
              grimblast --notify copysave "$1" "$img"
          fi
      }

      # small sleep delay is required so rofi menu doesnt appear in the screenshot
      case "$choice" in
      "All")
          delay=$(echo "0|3|5" | _rofi "$@")
          sleep 0.5
          sleep "$delay"
          screenshot screen
          ;;
      "Monitor")
          delay=$(echo "0|3|5" | _rofi "$@")
          sleep 0.5
          sleep "$delay"
          screenshot output
          ;;
      "Selection")
          screenshot area
          ;;
      "Window")
          delay=$(echo "0|3|5" | _rofi "$@")
          sleep 0.5
          sleep "$delay"
          screenshot active
          ;;
      esac
    '';
  };
  # run ocr on selected area and copy to clipboard
  hypr-ocr = pkgs.writeShellApplication {
    name = "hypr-ocr";
    runtimeInputs = [pkgs.tesseract5];
    text = ''
      img="$HOME/Pictures/Screenshots/ocr.png"

      grimblast save area "$img"
      teserract5 "$img" - | wl-copy
      rm "$img"
      notify-send "$(wl-paste)"
    '';
  };
in {
  config = lib.mkIf config.wayland.windowManager.hyprland.enable {
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
  };
}
