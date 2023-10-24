{pkgs, ...}: let
  sources = import ../_sources/generated.nix {inherit (pkgs) fetchFromGitHub fetchurl fetchgit dockerTools;};
  callPackageWithSource = sourceName: args: let
    origSource = sources.${sourceName};
    finalPackage = pkgs.callPackage ./${sourceName}.nix (args
      // {
        source =
          origSource
          // {
            version =
              if (builtins.hasAttr "date" origSource)
              then "unstable-${origSource.date}"
              else origSource.version;
          };
      });
  in
    # add maintainer info
    finalPackage
    // {
      meta =
        (finalPackage.meta or {})
        // {
          maintainers = [pkgs.lib.maintainers.iynaix];
        };
    };
  callMpvPlugin = sourceName:
    callPackageWithSource sourceName {
      mkMpvPlugin = mpvArg @ {
        outFile,
        inFile ? outFile,
        ...
      }:
        pkgs.stdenvNoCC.mkDerivation ({
            dontBuild = true;

            installPhase = ''
              runHook preInstall

              mkdir -p $out/share/mpv/scripts
              cp ${inFile} $out/share/mpv/scripts/${outFile}

              runHook postInstall
            '';

            passthru.scriptName = outFile;
          }
          // mpvArg);
    };
in {
  # rust dotfiles utils
  dotfiles-utils = pkgs.callPackage ./dotfiles-utils {};

  # mpv plugins
  mpv-chapterskip = callMpvPlugin "mpv-chapterskip";
  mpv-deletefile = callMpvPlugin "mpv-deletefile";
  mpv-dynamic-crop = callMpvPlugin "mpv-dynamic-crop";
  mpv-modernx = callPackageWithSource "mpv-modernx" {};
  mpv-nextfile = callMpvPlugin "mpv-nextfile";
  mpv-sub-select = callMpvPlugin "mpv-sub-select";
  mpv-subsearch = callMpvPlugin "mpv-subsearch";
  mpv-thumbfast-osc = callMpvPlugin "mpv-thumbfast-osc";

  vv = callPackageWithSource "vv" {};
}
