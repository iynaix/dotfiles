{
  hosts = [ "desktop" ];

  packages =
    { lib, pkgs, ... }:
    {
      awakened-poe-trade =
        (pkgs.awakened-poe-trade.override { commandLineArgs = [ "--ozone-platform=x11" ]; }).overrideAttrs
          (lib.custom.nvFetcherSources pkgs).awakened-poe-trade;
    };

  config =
    {
      pkgs,
      ...
    }:
    {
      # NOTE: POE is installed through steam
      environment.systemPackages = [
        pkgs.custom.awakened-poe-trade
        pkgs.custom.exiled-exchange-2
      ];

      # helium extensions
      programs.chromium.extensions = [
        # Better PathOfExile Trading
        "fhlinfpmdlijegjlpgedcmglkakaghnk"
        # Path of Exile Trade - Fuzzy Search
        "mkbkmkampdnnbehdldipgjhbablkmfba"
        # Looty
        # "ajfbflclpnpbjkfibijekgcombcgehbi"
      ];

      custom.programs = {
        umbriel.settings =
          let
            # poe1 / poe2 rules
            # hl.window_rule({ match = { tag = "poe" }, workspace = "5", fullscreen = true, idle_inhibit = "always" })
            poeArgs = {
              default_fullscreen = true;
              default_workspace = "5";
            };
            # woke poe1 / poe2 trade
            # hl.window_rule({ match = { tag = "apt" }, float = true, no_blur = true, no_shadow = true, border_size = 0 })
            aptArgs = {
              default_floating = true;
              blur = false;
            };
          in
          {
            window_rule =
              # poe1 / poe2
              [
                ({ match.title = "^Path of Exile( 2)?$"; } // poeArgs)
                ({ match.title = "^steam_app_(238960|2694490)$"; } // poeArgs)
              ]
              # woke poe1 / poe2 trade
              ++ [
                ({ match.title = "Awakened PoE Trade"; } // aptArgs)
                ({ match.title = "Exiled Exchange 2"; } // aptArgs)
              ];
          };
      };

      custom.persist = {
        home.directories = [
          ".config/awakened-poe-trade"
          ".config/exiled-exchange-2"
        ];
      };
    };
}
