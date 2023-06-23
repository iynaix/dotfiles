{
  pkgs,
  user,
  lib,
  host,
  config,
  ...
}: {
  config = {
    home-manager.users.${user} = {
      home.packages = with pkgs; [rofi-power-menu rofi-wayland];

      xdg.configFile = {
        "rofi/rofi-wifi-menu" = lib.mkIf (host == "laptop") {
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
