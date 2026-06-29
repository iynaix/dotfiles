{ inputs, ... }: {
  perSystem =
    { pkgs, ... }:
    {
      packages = {
        orca-slicer = inputs.wrappers.lib.wrapPackage {
          inherit pkgs;
          package = pkgs.orca-slicer;

          constructFiles = {
            # associate .step files with orca-slicer
            step-mime = {
              relPath = "/share/mime/packages/model-step.xml";
              content = /* xml */ ''
                <?xml version="1.0" encoding="UTF-8"?>
                <mime-info xmlns="http://www.freedesktop.org/standards/shared-mime-info">
                    <mime-type type="model/step">
                        <glob pattern="*.step"/>
                        <glob pattern="*.stp"/>
                        <comment>STEP CAD File</comment>
                    </mime-type>
                </mime-info>
              '';
            };
          };
        };
      };
    };

  flake.modules.nixos.programs_orca-slicer =
    { pkgs, ... }:
    {
      nixpkgs.overlays = [
        (_: _prev: {
          inherit (pkgs.custom) orca-slicer;
        })
      ];

      environment.systemPackages = [
        pkgs.orca-slicer # overlay-ed above
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

}
