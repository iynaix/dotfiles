{
  hosts = [ "desktop" ];

  config =
    { lib, pkgs, ... }:
    {
      # NOTE: POE is installed through steam
      environment.systemPackages = [
        (lib.hiPrio (
          pkgs.makeDesktopItem {
            name = "path-of-exile";
            desktopName = "Path of Exile";
            exec = "env DISPLAY=:0 steam steam://rungameid/238960";
            icon = "steam_icon_238960";
            terminal = false;
            type = "Application";
            categories = [ "Game" ];
          }
        ))
        (lib.hiPrio (
          pkgs.makeDesktopItem {
            name = "path-of-exile-2";
            desktopName = "Path of Exile 2";
            exec = "env DISPLAY=:0 steam steam://rungameid/2694490";
            icon = "steam_icon_2694490";
            terminal = false;
            type = "Application";
            categories = [ "Game" ];
          }
        ))
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
            poeArgs = {
              default_fullscreen = true;
              default_workspace = "5";
            };
          in
          {
            window_rule =
              # poe1 / poe2
              [
                ({ match.title = "^Path of Exile( 2)?$"; } // poeArgs)
                ({ match.title = "^steam_app_(238960|2694490)$"; } // poeArgs)
              ];
          };
      };
    };
}
