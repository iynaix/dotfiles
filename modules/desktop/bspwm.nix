{ pkgs, ... }: {
  imports = [ ./dunst.nix ./sxhkd.nix ];

  home = {
    packages = with pkgs; [ bspwm picom polybar rofi rofi-power-menu sxiv ];
  };
}
