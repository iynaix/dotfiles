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
        hyprland.luaText = /* lua */ ''
          -- poe1 / poe2
          hl.window_rule({ match = { title = "Path of Exile( 2)?" }, tag = "+poe" })
          hl.window_rule({ match = { initial_title = "Path of Exile( 2)?" }, tag = "+poe" })
          hl.window_rule({ match = { class = "steam_app_(238960|2694490)" }, tag = "+poe" })
          hl.window_rule({ match = { initial_class = "steam_app_(238960|2694490)" }, tag = "+poe" })

          -- poe1 / poe2 rules
          hl.window_rule({ match = { tag = "poe" }, workspace = "5", fullscreen = true, idle_inhibit = "always" })

          -- woke poe1 / poe2 trade
          hl.window_rule({ match = { title = "Awakened PoE Trade" }, tag = "+apt" })
          hl.window_rule({ match = { title = "Exiled Exchange 2" }, tag = "+apt" })
          hl.window_rule({ match = { tag = "apt" }, float = true, no_blur = true, no_shadow = true, border_size = 0 })
        '';

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
