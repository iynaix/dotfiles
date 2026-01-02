{
  lib,
  gcc14Stdenv,
  hyprland,
  fetchFromGitHub,
}:
gcc14Stdenv.mkDerivation (finalAttrs: {
  pname = "hyprNStack";
  version = "cbffba31ed820e2fbad6cb21ad0b15a051a9a4e7";
  src = fetchFromGitHub {
    owner = "zakk4223";
    repo = "hyprNstack";
    rev = finalAttrs.version;
    hash = "sha256-Cf0TFPrr+XLHRhbRF+zd2/YHgtS2KXskIFv0BQiYjLc=";
  };

  inherit (hyprland) nativeBuildInputs;

  buildInputs = [ hyprland.dev ] ++ hyprland.buildInputs;

  # Skip meson phases
  configurePhase = "true";
  mesonConfigurePhase = "true";
  mesonBuildPhase = "true";
  mesonInstallPhase = "true";

  buildPhase = /* sh */ ''
    make all
  '';

  installPhase = /* sh */ ''
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
