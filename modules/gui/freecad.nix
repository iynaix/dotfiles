{
  flake.nixosModules.freecad =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        pkgs.freecad-wayland
      ];

      custom.persist = {
        home = {
          directories = [
            ".config/FreeCAD"
            ".local/share/FreeCAD"
          ];
        };
      };
    };
}
