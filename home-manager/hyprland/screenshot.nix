{
  pkgs,
  host,
  lib,
  inputs,
  system,
  config,
  isNixOS,
  ...
}: let
  cfg = config.iynaix.hyprland;
  mod =
    if host == "vm"
    then "ALT"
    else "SUPER";
  # screenshot with rofi options to preselect
  hypr-screenshot = pkgs.writeShellScriptBin "hypr-screenshot" ''
    _rofi() {
        rofi -dmenu -sep '|' -disable-history true -cycle true -lines 4 -theme-str "mainbox { children: [listview]; }" "$@"
    }

    choice=$(echo "Selection|Window|Monitor|All" | _rofi)

    img="~/Pictures/Screenshots/$(date --iso-8601=seconds).png"

    # small sleep delay is required so rofi menu doesnt appear in the screenshot
    case "$choice" in
      "All")
        delay=$(echo "0|3|5" | _rofi)
        sleep 0.5
        sleep $delay
        grimblast --notify copysave screen $img
        ;;
      "Monitor")
        delay=$(echo "0|3|5" | _rofi)
        sleep 0.5
        sleep $delay
        grimblast --notify copysave output $img
        ;;
      "Selection")
        sleep 0.5
        sleep $delay
        grimblast --notify copysave area $img
        ;;
      "Window")
        delay=$(echo "0|3|5" | _rofi)
        sleep 0.5
        sleep $delay
        grimblast --notify copysave active $img
        ;;
    esac
  '';
  # run ocr on selected area and copy to clipboard
  hypr-ocr = with pkgs;
    pkgs.writeShellScriptBin "hypr-ocr" ''
      img="~/Pictures/Screenshots/ocr.png"

      grimblast save area $img
      ${tesseract5}/bin/tesseract $img - | wl-copy
      rm $img
      notify-send "$(wl-paste)"
    '';
in {
  config = lib.mkIf cfg.enable {
    home.packages = lib.mkIf isNixOS (with inputs.hyprwm-contrib.packages.${system}; [
      grimblast
      hyprprop
    ]);

    iynaix.hyprland.extraBinds = {
      bind = {
        "${mod}, backslash" = "exec, grimblast --notify copy area";
        "${mod}_SHIFT, backslash" = "exec, ${hypr-screenshot}/bin/hypr-screenshot";
        "${mod}_CTRL, backslash" = "exec, ${hypr-ocr}/bin/hypr-ocr";
      };
    };
  };
}
