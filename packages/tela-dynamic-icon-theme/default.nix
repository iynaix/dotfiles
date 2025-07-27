{
  lib,
  tela-icon-theme,
  colors ? {
    Blue = "#89b4fa";
  },
}:
tela-icon-theme.overrideAttrs (oldAttrs: {
  dontCheckForBrokenSymlinks = true; # takes forever

  postPatch =
    let
      themeColors = lib.pipe colors [
        lib.attrNames
        (map (name: ''"${name}"''))
        (lib.concatStringsSep " ")
      ];
      themeHelp =
        lib.concatLines (lib.mapAttrsToList (name: _: "${name}\t\t\t\t${name} color folder version") colors)
        + ''
          \nBy default, only the ${lib.head (lib.attrNames colors)} one is selected.
        '';
      themeIf = lib.concatLines (
        lib.mapAttrsToList (name: color: ''
          ${name})
            local -r theme_color='${color}';
            local -r theme_back_color='#ffffff';
            ;;
        '') colors
      );
    in
    (oldAttrs.postPatch or "")
    + ''
      # add the nix logo
      cp ${./nix.svg} src/scalable/mimetypes/text-x-nix.svg

      substitute ${./install.sh} install.sh \
        --replace-fail @THEME_COLORS@ "${themeColors}" \
        --replace-fail @THEME_HELP@ "${themeHelp}" \
        --replace-fail @THEME_IF@ "${themeIf}"
    '';

  # removed jdupes as it is slow and rather pointless
  installPhase = ''
    runHook preInstall

    patchShebangs install.sh
    mkdir -p $out/share/icons
    ./install.sh -a -d $out/share/icons

    runHook postInstall
  '';

  # add nix logo for *.nix files through the use of a mimetype
  postInstall = (oldAttrs.postInstall or "") + ''
    mkdir -p $out/share/mime/packages
    cp ${./nix.xml} $out/share/mime/packages/nix.xml
  '';
})
