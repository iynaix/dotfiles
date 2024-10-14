{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.custom = with lib; {
    gaming.enable = mkEnableOption "Gaming on Nix";
  };

  config = lib.mkIf config.custom.gaming.enable {
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
