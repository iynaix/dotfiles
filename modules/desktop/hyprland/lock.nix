{
  pkgs,
  lib,
  host,
  user,
  config,
  ...
}: let
  mod =
    if host == "vm"
    then "ALT"
    else "SUPER";
  hypr-lock =
    pkgs.writeShellScriptBin "hypr-lock"
    /*
    sh
    */
    ''
      source $HOME/.cache/wal/colors.sh

      ${pkgs.swaylock-effects}/bin/swaylock \
        --clock \
        --screenshots \
        --fade-in 0.2 \
        --font ${config.iynaix.font.regular} \
        --effect-blur 8x5 \
        --effect-vignette 0.4:0.4 \
        --indicator-radius 100 \
        --indicator-thickness 5 \
        --text-color ''${foreground} \
        --inside-wrong-color ''${color1} \
        --ring-wrong-color ''${color1} \
        --inside-clear-color ''${background} \
        --ring-clear-color ''${background} \
        --inside-ver-color ''${color6} \
        --ring-ver-color ''${color6} \
        --ring-color ''${color6} \
        --key-hl-color ''${color5} \
        --line-color ''${color8} \
        --inside-color 00161925 \
        --separator-color 00000000
    '';
in {
  config = lib.mkIf config.iynaix.hyprland.enable {
    security.pam.services.swaylock = {
      text = "auth include login";
    };

    home-manager.users.${user} = {
      home.packages = [hypr-lock];
    };

    iynaix.hyprland.extraBinds = {
      bind = {
        "${mod}, l" = "exec, hypr-lock";
      };
    };
  };
}
