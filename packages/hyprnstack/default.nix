{
  lib,
  gcc14Stdenv,
  hyprland,
  source,
}:
gcc14Stdenv.mkDerivation (
  source
  // {
    inherit (hyprland) nativeBuildInputs;

    buildInputs = [ hyprland ] ++ hyprland.buildInputs;

    # Skip meson phases
    configurePhase = "true";
    mesonConfigurePhase = "true";
    mesonBuildPhase = "true";
    mesonInstallPhase = "true";

    buildPhase = # sh
      ''
        make all
      '';

    installPhase = # sh
      ''
        mkdir -p $out/lib
        cp nstackLayoutPlugin.so $out/lib/libhyprNStack.so
      '';

    meta = {
      homepage = "https://github.com/zakk4223/hyprNStack";
      description = "Hyprland HyprNStack Plugin";
      maintainers = [ lib.maintainers.iynaix ];
      platforms = lib.platforms.linux;
    };
  }
)
