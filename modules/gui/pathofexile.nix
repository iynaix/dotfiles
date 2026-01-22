topLevel: {
  flake.nixosModules.path-of-building =
    { pkgs, ... }:
    let
      source = (pkgs.callPackage ../../_sources/generated.nix { }).rusty-path-of-building;
    in
    {
      # covers both poe1 and poe2
      environment.systemPackages = [
        # use latest version
        (pkgs.rusty-path-of-building.overrideAttrs (
          source
          // {
            cargoDeps = pkgs.rustPlatform.importCargoLock {
              lockFile = source.src + "/Cargo.lock";
              allowBuiltinFetchGit = true;
            };
          }
        ))
      ];

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
      environment.systemPackages = with self.packages.${pkgs.stdenv.hostPlatform.system}; [
        awakened-poe-trade
        exiled-exchange-2
      ];

      custom.programs = {
        hyprland.settings = {
          # NOTE: multiple rules so they are OR-ed
          windowrule = [
            # poe1 / poe2
            "match:title (Path of Exile( 2)?), tag +poe"
            "match:initial_title (Path of Exile( 2)?), tag +poe"
            "match:class (steam_app_(238960|2694490)), tag +poe"
            "match:initial_class (steam_app_(238960|2694490)), tag +poe"
            # poe1 / poe2 rules
            "match:tag poe, workspace 5, fullscreen on"
            # woke poe1 / poe2 trade
            "match:title (Awakened PoE Trade), tag +apt"
            "match:title (Exiled Exchange 2), tag +apt"
            "match:tag apt, no_blur on, no_shadow on, border_size 0"
          ];
        };

        niri.settings.config = /* kdl */ ''
          // poe1 / poe2
          window-rule {
              match title="^Path of Exile( 2)?$"
              match app-id="^steam_app_(238960|2694490)$"

              open-on-workspace "5"
              open-fullscreen true
          }

          // Trade Tools (Awakened PoE Trade / Exiled Exchange 2)
          window-rule {
              match title="^Awakened PoE Trade$"
              match title="^Exiled Exchange 2$"

              open-floating true
              open-focused true
          }
        '';
      };

      custom.persist = {
        home.directories = [
          ".config/awakened-poe-trade"
          ".config/exiled-exchange-2"
        ];
      };
    };
}
