topLevel: {
  flake.nixosModules.path-of-building =
    { pkgs, ... }:
    {
      # covers both poe1 and poe2
      environment.systemPackages = [ pkgs.rusty-path-of-building ];

      custom.persist = {
        home = {
          directories = [
            ".local/share/RustyPathOfBuilding1"
            ".local/share/RustyPathOfBuilding2"
          ];
        };
      };
    };

  flake.nixosModules.path-of-exile =
    { pkgs, self, ... }:
    {
      imports = with topLevel.config.flake.nixosModules; [
        path-of-building
        steam
      ];

      # NOTE: POE is installed through steam
      environment.systemPackages = [
        self.packages.${pkgs.stdenv.hostPlatform.system}.awakened-poe-trade
      ];

      custom.programs.hyprland.settings = {
        windowrulev2 = [
          # poe1
          "tag +poe, title:(Path of Exile)"
          "tag +poe, initialTitle:(Path of Exile)"
          "tag +poe, class:(steam_app_238960)"
          "tag +poe, initialClass:(steam_app_238960)"
          # poe2
          "tag +poe, title:(Path of Exile 2)"
          "tag +poe, initialTitle:(Path of Exile 2)"
          "tag +poe, class:(steam_app_2694490)"
          "tag +poe, initialClass:(steam_app_2694490)"
          # poe1 / poe2 rules
          "workspace 5, tag:poe"
          "fullscreen, tag:poe"
          # woke poe1 / poe2 trade
          "tag +apt, title:(Awakened PoE Trade)"
          "tag +apt, title:(Exiled Exchange 2)"
          "float, tag:apt "
          "noblur, tag:apt"
          "nofocus, tag:apt # Disable auto-focus"
          "noshadow, tag:apt"
          "noborder, tag:apt"
          "pin, tag:apt"
          "renderunfocused, tag:apt"
          "size 100% 100%, tag:apt"
          "center, tag:apt"
        ];
      };

      custom.persist = {
        home.directories = [
          ".config/awakened-poe-trade"
          ".config/exiled-exchange-2"
        ];
      };
    };
}
