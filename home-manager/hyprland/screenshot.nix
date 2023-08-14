{
  config,
  inputs,
  isNixOS,
  lib,
  pkgs,
  ...
}: let
  cfg = config.iynaix.hyprland;
  # screenshot with rofi options to preselect
  hypr-screenshot = pkgs.writeShellApplication {
    name = "hypr-screenshot";
    runtimeInputs = [inputs.hyprwm-contrib.packages.${pkgs.system}.grimblast];
    text = ''
      _rofi() {
          rofi -dmenu -sep '|' -disable-history true -cycle true -lines 4 -theme-str "mainbox { children: [listview]; }" "$@"
      }

      choice=$(echo "Selection|Window|Monitor|All" | _rofi)

      img="$HOME/Pictures/Screenshots/$(date --iso-8601=seconds).png"

      # small sleep delay is required so rofi menu doesnt appear in the screenshot
      case "$choice" in
        "All")
          delay=$(echo "0|3|5" | _rofi "$@")
          sleep 0.5
          sleep "$delay"
          grimblast --notify copysave screen "$img"
          ;;
        "Monitor")
          delay=$(echo "0|3|5" | _rofi "$@")
          sleep 0.5
          sleep "$delay"
          grimblast --notify copysave output "$img"
          ;;
        "Selection")
          grimblast --notify copysave area "$img"
          ;;
        "Window")
          delay=$(echo "0|3|5" | _rofi "$@")
          sleep 0.5
          sleep "$delay"
          grimblast --notify copysave active "$img"
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
  config = lib.mkIf cfg.enable {
    home.packages =
      [
        hypr-ocr
        hypr-screenshot
      ]
      ++ (lib.optionals isNixOS (with inputs.hyprwm-contrib.packages.${pkgs.system}; [
        grimblast
        hyprprop
      ]));

    wayland.windowManager.hyprland.settings = {
      bind = [
        "$mod, backslash, exec, grimblast --notify copy area"
        "$mod_SHIFT, backslash, exec, hypr-screenshot"
        "$mod_CTRL, backslash, exec, hypr-ocr"
      ];
    };
  };
}
