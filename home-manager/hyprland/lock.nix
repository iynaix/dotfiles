{
  config,
  isLaptop,
  lib,
  pkgs,
  ...
}:
let
  lock = pkgs.writeShellScriptBin "lock" ''
    sh "${config.xdg.cacheHome}/wallust/lock"
  '';
in
lib.mkIf isLaptop {
  home.packages = [ lock ];

  wayland.windowManager.hyprland.settings = {
    bind = [ "$mod, x, exec, ${lib.getExe lock}" ];

    # handle laptop lid
    bindl = [ ",switch:Lid Switch, exec, ${lib.getExe lock}" ];
  };

  custom.wallust.templates = {
    "lock" = {
      enable = lib.elem lock config.home.packages;
      text = ''
        ${lib.getExe pkgs.swaylock-effects} \
          --clock \
          --screenshots \
          --fade-in 0.2 \
          --font "${config.custom.fonts.regular}" \
          --effect-blur 8x5 \
          --effect-vignette 0.4:0.4 \
          --indicator-radius 100 \
          --indicator-thickness 5 \
          --text-color "{{foreground}}" \
          --inside-wrong-color "{{color1}}" \
          --ring-wrong-color "{{color1}}" \
          --inside-clear-color "{{background}}" \
          --ring-clear-color "{{background}}" \
          --inside-ver-color "{{color6}}" \
          --ring-ver-color "{{color6}}" \
          --ring-color "{{color6}}" \
          --key-hl-color "{{color5}}" \
          --line-color "{{color8}}" \
          --inside-color "00161925" \
          --separator-color "00000000"
      '';
      target = "${config.xdg.cacheHome}/wallust/lock";
    };
  };
}
