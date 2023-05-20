{
  pkgs,
  user,
  lib,
  host,
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
          @theme "/home/${user}/.cache/wal/colors-rofi-dark.rasi"
        '';

        "wal/templates/colors-rofi-dark.rasi".source = ./rofi-iynaix.rasi;
      };
    };
  };
}
