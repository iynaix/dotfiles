{
  pkgs,
  lib,
  config,
  ...
}: let
  lock = pkgs.writeShellScriptBin "lock" ''
    sh "$HOME/.cache/wallust/lock"
  '';
in {
  config = lib.mkIf config.wayland.windowManager.hyprland.enable {
    home.packages = [lock];

    wayland.windowManager.hyprland.settings = {
      bind = ["$mod, x, exec, lock"];
    };

    iynaix.wallust.entries = {
      "lock" = {
        enable = builtins.elem lock config.home.packages;
        text = ''
          ${pkgs.swaylock-effects}/bin/swaylock \
            --clock \
            --screenshots \
            --fade-in 0.2 \
            --font "${config.iynaix.fonts.regular}" \
            --effect-blur 8x5 \
            --effect-vignette 0.4:0.4 \
            --indicator-radius 100 \
            --indicator-thickness 5 \
            --text-color "{foreground}" \
            --inside-wrong-color "{color1}" \
            --ring-wrong-color "{color1}" \
            --inside-clear-color "{background}" \
            --ring-clear-color "{background}" \
            --inside-ver-color "{color6}" \
            --ring-ver-color "{color6}" \
            --ring-color "{color6}" \
            --key-hl-color "{color5}" \
            --line-color "{color8}" \
            --inside-color "00161925" \
            --separator-color "00000000"
        '';
        target = "~/.cache/wallust/lock";
      };
    };
  };
}
