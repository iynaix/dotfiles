{
  pkgs,
  user,
  lib,
  host,
  ...
}: {
  config = {
    home-manager.users.${user} = {
      home = {
        packages = with pkgs; [rofi-power-menu rofi-wayland];

        file.".config/rofi/rofi-wifi-menu" = lib.mkIf (host == "laptop") {
          source = ./rofi-wifi-menu.sh;
        };

        file.".config/rofi/config.rasi".text = ''
          @theme "/home/${user}/.cache/wal/colors-rofi-dark.rasi"
        '';

        file.".config/wal/templates/colors-rofi-dark.rasi".source = ./rofi-iynaix.rasi;
      };
    };
  };
}
