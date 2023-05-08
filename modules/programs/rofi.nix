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

    nixpkgs.overlays = [
      (self: super: {
        rofi-power-menu = super.rofi-power-menu.overrideAttrs (oldAttrs: {
          src = pkgs.fetchFromGitHub {
            owner = "jluttine";
            repo = "rofi-power-menu";
            rev = "3.1.0";
            sha256 = "sha256-VPCfmCTr6ADNT7MW4jiqLI/lvTjlAu1QrCAugiD0toU=";
          };
        });
      })
    ];
  };
}
