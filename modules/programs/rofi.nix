{
  pkgs,
  user,
  lib,
  config,
  isLaptop,
  ...
}: {
  config = {
    home-manager.users.${user} = {
      home.packages = with pkgs; [rofi-power-menu rofi-wayland];

      xdg.configFile = {
        "rofi/rofi-wifi-menu" = lib.mkIf isLaptop {
          source = ./rofi-wifi-menu.sh;
        };

        "rofi/config.rasi".text = ''
          @theme "/home/${user}/.cache/wallust/rofi.rasi"
        '';
      };
    };

    iynaix.wallust.entries."rofi.rasi" = {
      enable = config.iynaix.wallust.rofi;
      text = builtins.readFile ./rofi-iynaix.rasi;
      target = "~/.cache/wallust/rofi.rasi";
    };
  };
}
