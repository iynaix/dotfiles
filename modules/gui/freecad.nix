{
  hosts = [ "desktop" ];

  config =
    {
      inputs,
      system,
      ...
    }:
    {
      environment.systemPackages = [
        # pkgs.freecad-wayland
        (inputs.multiverse.multiverse.${system}.at "8ce4ef6cb6f8").freecad-wayland
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
