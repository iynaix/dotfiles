{
  config,
  host,
  lib,
  pkgs,
  ...
}:
let
  # software rendering workaround for nvidia, see:
  # https://github.com/SoftFever/OrcaSlicer/issues/6433#issuecomment-2552029299
  nvidiaSoftwareRenderingWorkaround =
    bin: pkg:
    if (host == "desktop") then
      pkgs.symlinkJoin {
        name = bin;
        paths = [ pkg ];
        buildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
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
  options.custom = with lib; {
    # option not called 3d printing because of attribute name restrictions
    bambu.enable = mkEnableOption "3dprinting";
  };

  config = lib.mkIf (!config.custom.headless) {
    home.packages = with pkgs; [
      # bambu-studio doesn't show the prepare / preview pane on nvidia 565:
      # https://github.com/bambulab/BambuStudio/issues/5166
      (nvidiaSoftwareRenderingWorkaround "bambu-studio"
        # wait for https://github.com/NixOS/nixpkgs/pull/376159 to be merged
        (bambu-studio.override { boost = boost186; })
      )
      # freecad segfaults on starup on nvidia
      # https://github.com/NixOS/nixpkgs/issues/366299
      (nvidiaSoftwareRenderingWorkaround "FreeCAD" freecad-wayland)
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
