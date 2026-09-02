{
  hosts = [ "desktop" ];

  config =
    { libCustom, pkgs, ... }:
    let
      sources = libCustom.nvFetcherSources pkgs;
    in
    {
      # NOTE: POE is installed through steam
      environment.systemPackages = [
        # don't expose in perSystem as it requires a patched nixpkgs
        ((pkgs.awakened-poe-trade.override { commandLineArgs = [ "--ozone-platform=x11" ]; }).overrideAttrs
          sources.awakened-poe-trade
        )
        (
          (pkgs.custom.exiled-exchange-2.override { commandLineArgs = [ "--ozone-platform=x11" ]; })
          .overrideAttrs
          sources.exiled-exchange-2
        )
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
        hyprland.settings = /* lua */ ''
          -- poe1 / poe2
          hl.window_rule({ match = { title = "Path of Exile( 2)?" }, tag = "+poe" })
          hl.window_rule({ match = { class = "steam_app_(238960|2694490)" }, tag = "+poe" })

          -- poe1 / poe2 rules
          hl.window_rule({ match = { tag = "poe" }, workspace = "5", fullscreen = true, idle_inhibit = "always" })

          -- woke poe1 / poe2 trade
          hl.window_rule({ match = { title = "Awakened PoE Trade" }, tag = "+apt" })
          hl.window_rule({ match = { title = "Exiled Exchange 2" }, tag = "+apt" })
          hl.window_rule({ match = { tag = "apt" }, float = true, no_blur = true, no_shadow = true, border_size = 0 })
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
