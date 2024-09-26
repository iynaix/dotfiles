{ pkgs, ... }:

{
  config = {
    home.packages = with pkgs; [
      heroic
      steam-run
      protonup-qt
      wineWowPackages.waylandFull
    ];
    custom.persist = {
      home.directories = [
        "Games"
        ".config/heroic"
      ];
    };
  };
}
