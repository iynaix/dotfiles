{
  hosts = [ "desktop" ];

  packages =
    { pkgs, ... }:
    {
      awakened-poe-trade = pkgs.awakened-poe-trade.override {
        commandLineArgs = [ "--ozone-platform=x11" ];
      };
    };

  config = { pkgs, ... }: {
    environment.systemPackages = [
      pkgs.custom.awakened-poe-trade
    ];

    custom.programs = {
      umbriel.settings = {
        window_rule = [
          {
            match.title = "Awakened PoE Trade";
            default_floating = true;
            blur = false;
          }
        ];
      };
    };

    custom.persist = {
      home.directories = [
        ".config/awakened-poe-trade"
      ];
    };
  };
}
