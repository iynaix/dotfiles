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

      # window rules for awakened-poe-trade
      custom.programs.hyprland.settings = {
        windowrulev2 = [
          "tag +poe, title:(Path of Exile)"
          "tag +poe, class:(steam_app_238960)"
          "workspace 5, tag:poe"
          "fullscreen, tag:poe"
          "tag +apt, title:(Awakened PoE Trade)"
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
        ];
      };
    };
}
