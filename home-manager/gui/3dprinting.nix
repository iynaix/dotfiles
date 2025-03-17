{
  config,
  host,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkEnableOption
    mkIf
    mkMerge
    ;
  # software rendering workaround for nvidia, see:
  # https://github.com/SoftFever/OrcaSlicer/issues/6433#issuecomment-2552029299
  nvidiaSoftwareRenderingWorkaround =
    bin: pkg:
    if (host == "desktop") then
      pkgs.symlinkJoin {
        name = bin;
        paths = [ pkg ];
        buildInputs = [ pkgs.makeWrapper ];
        # use zink workaround for nvidia, see:
        # https://github.com/klylabs/OrcaSlicer/blob/5d6bc146e8b6a1eba7db78d2c6a706f51d49ec67/src/platform/unix/BuildLinuxImage.sh.in#L60
        postBuild = # sh
          ''
            wrapProgram $out/bin/${bin} \
              --set __GLX_VENDOR_LIBRARY_NAME mesa \
              --set __EGL_VENDOR_LIBRARY_FILENAMES ${pkgs.mesa}/share/glvnd/egl_vendor.d/50_mesa.json \
              --set MESA_LOADER_DRIVER_OVERRIDE zink \
              --set GALLIUM_DRIVER zink \
              --set WEBKIT_DISABLE_DMABUF_RENDERER 1
          '';
        meta.mainProgram = bin;
      }
    else
      pkg;
in
{
  options.custom = {
    # option not called 3dprinting because of attribute name restrictions
    printing3d.enable = mkEnableOption "3d printing";
    modelling3d.enable = mkEnableOption "3d modelling";
  };

  config = mkIf (!config.custom.headless) (mkMerge [
    # slicers
    (mkIf config.custom.printing3d.enable {
      home.packages = [
        (pkgs.symlinkJoin {
          name = "orca-slicer";
          paths = [
            # software rendering workaround for nvidia, see:
            # https://github.com/SoftFever/OrcaSlicer/issues/6433#issuecomment-2552029299
            (nvidiaSoftwareRenderingWorkaround "orca-slicer" pkgs.orca-slicer)
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
        mimeApps = {
          associations.added."model/step" = "OrcaSlicer.desktop";
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
    })
    # CAD
    (mkIf config.custom.modelling3d.enable {
      home.packages = [
        # freecad segfaults on starup on nvidia
        # https://github.com/NixOS/nixpkgs/issues/366299
        (nvidiaSoftwareRenderingWorkaround "FreeCAD" pkgs.freecad-wayland)
      ];

      custom.persist = {
        home = {
          directories = [
            ".config/FreeCAD"
            ".local/share/FreeCAD"
          ];
        };
      };
    })
  ]);
}
