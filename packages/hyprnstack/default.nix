{
  lib,
  gcc14Stdenv,
  hyprland,
  fetchFromGitHub,
}:
gcc14Stdenv.mkDerivation (finalAttrs: {
  pname = "hyprNStack";
  version = "1959ecbc50071e5e182b6ce0edff92245870caf1";
  src = fetchFromGitHub {
    owner = "zakk4223";
    repo = "hyprNstack";
    rev = finalAttrs.version;
    sha256 = "sha256-LL1+gGBQcb+P0hiCGhHKDIhy7+UqwUBmU+kh0YQTYI0=";
  };

  inherit (hyprland) nativeBuildInputs;

  buildInputs = [ hyprland.dev ] ++ hyprland.buildInputs;

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
})
