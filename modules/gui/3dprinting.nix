{
  flake.nixosModules.orca-slicer =
    { pkgs, ... }:
    {
      environment.systemPackages = [
        (pkgs.symlinkJoin {
          name = "orca-slicer";
          paths = [
            pkgs.orca-slicer
            # associate step files with orca-slicer
            (pkgs.writeTextFile {
              name = "model-step.xml";
              text = # xml
                ''
                  <?xml version="1.0" encoding="UTF-8"?>
                  <mime-info xmlns="http://www.freedesktop.org/standards/shared-mime-info">
                      <mime-type type="model/step">
                          <glob pattern="*.step"/>
                          <glob pattern="*.stp"/>
                          <comment>STEP CAD File</comment>
                      </mime-type>
                  </mime-info>
                '';
              executable = true;
              destination = "/share/mime/packages/model-step.xml";
            })
          ];
          meta.mainProgram = "orca-slicer";
        })
      ];

      xdg = {
        mime = {
          addedAssociations."model/step" = "OrcaSlicer.desktop";
          # allow orca-slicer to be open bambu studio links
          defaultApplications = {
            "model/step" = "OrcaSlicer.desktop";
            "x-scheme-handler/orcaslicer" = "OrcaSlicer.desktop";
            "x-scheme-handler/bambustudio" = "OrcaSlicer.desktop"; # makerworld
            "x-scheme-handler/prusaslicer" = "OrcaSlicer.desktop"; # printables
          };
        };
      };

      custom.persist = {
        home = {
          directories = [
            ".config/OrcaSlicer"
          ];
        };
      };
    };

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
