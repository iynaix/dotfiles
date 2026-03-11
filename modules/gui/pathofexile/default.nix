{ self, ... }:
{
  flake.modules.nixos.programs_path-of-exile =
    { pkgs, ... }:
    let
      source = (self.libCustom.nvFetcherSources pkgs).awakened-poe-trade;
      # don't expose in perSystem as it requires a patched nixpkgs
      awakened-poe-trade' =
        (pkgs.awakened-poe-trade.override { commandLineArgs = [ "--ozone-platform=x11" ]; }).overrideAttrs
          source;
    in
    {
      # NOTE: POE is installed through steam
      environment.systemPackages = with pkgs.custom; [
        awakened-poe-trade'
        exiled-exchange-2
      ];

      # helium extensions
      programs.chromium.extensions = [
        # Better PathOfExile Trading
        "fhlinfpmdlijegjlpgedcmglkakaghnk"
        # Path of Exile Trade - Fuzzy Search
        "mkbkmkampdnnbehdldipgjhbablkmfba"
        # Looty
        # "ajfbflclpnpbjkfibijekgcombcgehbi"
        # Old Reddit Redirect
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
            "match:tag poe, workspace 5, fullscreen on, idle_inhibit always"
            # woke poe1 / poe2 trade
            "match:title (Awakened PoE Trade), tag +apt"
            "match:title (Exiled Exchange 2), tag +apt"
            # "match:tag apt, float on, no_blur on, no_shadow on, no_focus on, render_unfocused on, border_size 0"
            "match:tag apt, float on, no_blur on, no_shadow on, border_size 0"
          ];
        };

        niri.settings.window-rules = [
          # poe1 / poe2
          {
            matches = [
              { title = "^Path of Exile( 2)?$"; }
              { app-id = "^steam_app_(238960|2694490)$"; }
            ];

            open-on-workspace = "5";
            open-fullscreen = true;
          }

          # Trade Tools (Awakened PoE Trade / Exiled Exchange 2)
          {
            matches = [
              { title = "^Awakened PoE Trade$"; }
              { title = "^Exiled Exchange 2$"; }
            ];

            open-floating = true;
            open-focused = true;
          }
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
