{
  lib,
  tela-icon-theme,
  colors ? {
    Blue = "#89b4fa";
  },
}:
tela-icon-theme.overrideAttrs (oldAttrs: {
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
      substitute ${./install.sh} install.sh \
        --replace-fail @@THEME_COLORS@@ "${themeColors}" \
        --replace-fail @@THEME_HELP@@ "${themeHelp}" \
        --replace-fail @@THEME_IF@@ "${themeIf}"
    '';
})
