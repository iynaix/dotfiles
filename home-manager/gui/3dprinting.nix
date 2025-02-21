{
  config,
  host,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf mkMerge;
  # software rendering workaround for nvidia, see:
  # https://github.com/SoftFever/OrcaSlicer/issues/6433#issuecomment-2552029299
  nvidiaSoftwareRenderingWorkaround =
    bin: pkg:
    if (host == "desktop") then
      pkgs.symlinkJoin {
        name = bin;
        paths = [ pkg ];
        buildInputs = [ pkgs.makeWrapper ];
        postBuild = # sh
          ''
            wrapProgram $out/bin/${bin} \
              --set __GLX_VENDOR_LIBRARY_NAME mesa \
              --set __EGL_VENDOR_LIBRARY_FILENAMES ${pkgs.mesa.drivers}/share/glvnd/egl_vendor.d/50_mesa.json
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
      home.packages = with pkgs; [
        # orca-slicer doesn't show the prepare / preview pane on nvidia 565:
        # https://github.com/SoftFever/OrcaSlicer/issues/6433#issuecomment-2552029299
        (nvidiaSoftwareRenderingWorkaround "orca-slicer" orca-slicer)
      ];

      # allow orca-slicer to be open bambu studio links
      xdg.mimeApps.defaultApplications = {
        "x-scheme-handler/orcaslicer" = "OrcaSlicer.desktop";
        "x-scheme-handler/bambustudio" = "OrcaSlicer.desktop"; # makerworld
        "x-scheme-handler/prusaslicer" = "OrcaSlicer.desktop"; # printables
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
      home.packages = with pkgs; [
        # freecad segfaults on starup on nvidia
        # https://github.com/NixOS/nixpkgs/issues/366299
        (nvidiaSoftwareRenderingWorkaround "FreeCAD" freecad-wayland)
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
