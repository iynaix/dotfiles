{
  config,
  isLaptop,
  lib,
  pkgs,
  ...
}: {
  programs.rofi = {
    enable = true;
    package = pkgs.rofi-wayland;
  };

  home.packages = with pkgs; [rofi-power-menu];

  xdg.configFile = {
    "rofi/rofi-wifi-menu" = lib.mkIf isLaptop {
      source = ./rofi-wifi-menu.sh;
    };

    "rofi/config.rasi".text = ''
      @theme "~/.cache/wallust/rofi.rasi"
    '';
  };

  iynaix.wallust.entries."rofi.rasi" = {
    enable = config.programs.rofi.enable;
    text = builtins.readFile ./rofi-iynaix.rasi;
    target = "~/.cache/wallust/rofi.rasi";
  };
}
