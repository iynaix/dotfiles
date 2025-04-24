{
  lib,
  gcc14Stdenv,
  hyprland,
  fetchFromGitHub,
}:
gcc14Stdenv.mkDerivation {
  pname = "hyprNStack";
  version = "e5d7cb332148898a86fbdb7477531e20442347d3";
  src = fetchFromGitHub {
    owner = "zakk4223";
    repo = "hyprNstack";
    rev = "e5d7cb332148898a86fbdb7477531e20442347d3";
    fetchSubmodules = false;
    sha256 = "sha256-XRiqgQHHOsNp54jBr4fj1j2lVrRgifS0pOfa3NLerGA=";
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
}
