{ pkgs, host, user, lib, config, ... }:
let
  cfg = config.iynaix.hyprland;
  mod = if host == "vm" then "ALT" else "SUPER";
  grimblast = "${pkgs.hyprwm-contrib.grimblast}/bin/grimblast --notify";
  hypr-screenshot = pkgs.writeShellScriptBin "hypr-screenshot" /* sh */ ''
    _rofi() {
        rofi -dmenu -sep '|' -disable-history true -cycle true -lines 4 -theme-str "mainbox { children: [listview]; }" "$@"
    }

    choice=$(echo "Selection|Window|Monitor|All" | _rofi)

    screenshots=~/Pictures/Screenshots
    mkdir -p $screenshots

    img="$screenshots/$(date --iso-8601=seconds).png"

    # small sleep delay is required so rofi menu doesnt appear in the screenshot
    case "$choice" in
      "All")
        delay=$(echo "0|3|5" | _rofi)
        sleep 0.5
        sleep $delay
        ${grimblast} copysave screen $img
        ;;
      "Monitor")
        delay=$(echo "0|3|5" | _rofi)
        sleep 0.5
        sleep $delay
        ${grimblast} copysave output $img
        ;;
      "Selection")
        sleep 0.5
        sleep $delay
        ${grimblast} copysave area $img
        ;;
      "Window")
        delay=$(echo "0|3|5" | _rofi)
        sleep 0.5
        sleep $delay
        ${grimblast} copysave active $img
        ;;
    esac
  '';
in
{
  config = lib.mkIf cfg.enable {
    home-manager.users.${user} = {
      home.packages = [ hypr-screenshot ];
    };

    iynaix.hyprland.extraBinds = {
      # screenshots
      bind = {
        "${mod}, backslash" = "exec, ${grimblast} copy area";
        "${mod}_SHIFT, backslash" = "exec, ${hypr-screenshot}/bin/hypr-screenshot";
      };
    };
  };
}
