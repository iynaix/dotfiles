{
  pkgs,
  lib,
  host,
  config,
  ...
}: let
  mod =
    if host == "vm"
    then "ALT"
    else "SUPER";
  hypr-lock = pkgs.writeShellApplication {
    name = "hypr-lock";
    runtimeInputs = [pkgs.swaylock-effects];
    text = ''
      # ignore sourcing errors
      # shellcheck disable=SC1091
      source "$HOME/.cache/wallust/colors.sh"

      # ignore undefined variables warnings from colors.sh
      # shellcheck disable=SC2154
      swaylock \
        --clock \
        --screenshots \
        --fade-in 0.2 \
        --font "${config.iynaix.fonts.regular}" \
        --effect-blur 8x5 \
        --effect-vignette 0.4:0.4 \
        --indicator-radius 100 \
        --indicator-thickness 5 \
        --text-color "$foreground" \
        --inside-wrong-color "$color1" \
        --ring-wrong-color "$color1" \
        --inside-clear-color "$background" \
        --ring-clear-color "$background" \
        --inside-ver-color "$color6" \
        --ring-ver-color "$color6" \
        --ring-color "$color6" \
        --key-hl-color "$color5" \
        --line-color "$color8" \
        --inside-color "00161925" \
        --separator-color "00000000"
    '';
  };
in {
  config = lib.mkIf config.iynaix.hyprland.enable {
    home.packages = [hypr-lock];

    wayland.windowManager.hyprland.settings = {
      bind = [
        "$mod, x, exec, hypr-lock"
      ];
    };
  };
}
