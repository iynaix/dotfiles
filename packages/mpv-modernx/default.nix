{
  lib,
  buildLua,
  makeFontsConf,
  source,
}:
buildLua (
  finalAttrs:
  (
    source
    // {
      dontBuild = true;

      postInstall = ''
        mkdir -p $out/share/fonts/truetype
        cp Material-Design-Iconic-Font.ttf $out/share/fonts/truetype
      '';

      scriptPath = "modernx.lua";
      passthru.scriptName = "modernx.lua";

      # In order for mpv to find the custom font, we need to adjust the fontconfig search path.
      passthru.extraWrapperArgs = [
        "--set"
        "FONTCONFIG_FILE"
        (toString (makeFontsConf {
          fontDirectories = [ "${finalAttrs.finalPackage}/share/fonts" ];
        }))
      ];

      meta = {
        description = "An MPV OSC script based on mpv-osc-modern that aims to mirror the functionality of MPV's stock OSC while with a more modern-looking interface.";
        homepage = "https://github.com/cyl0/ModernX";
        maintainers = [ lib.maintainers.iynaix ];
      };
    }
  )
)
