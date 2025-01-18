{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.custom = with lib; {
    # option not called 3d printing because of attribute name restrictions
    bambu.enable = mkEnableOption "3dprinting";
  };

  config = lib.mkIf (!config.custom.headless) {
    home.packages = with pkgs; [
      bambu-studio
      freecad-wayland
    ];

    custom.persist = {
      home = {
        directories = [
          ".config/BambuStudio"
          ".config/FreeCAD"
          ".local/share/FreeCAD"
        ];
      };
    };
  };
}
