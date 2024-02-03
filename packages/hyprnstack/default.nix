{
  lib,
  fetchFromGitHub,
  gcc13Stdenv,
  hyprland,
}:
gcc13Stdenv.mkDerivation {
  pname = "hyprNStack";
  version = "0.1";

  src = fetchFromGitHub {
    owner = "zakk4223";
    repo = "hyprNStack";
    rev = "5add1437f68b8116ad66a89fd8446e065bb392df";
    sha256 = "sha256-8uvArhdtPL5CIJ1EVs5ZjjwHZVr9TWpwxwkBoZ2WF24=";
  };

  preConfigure = ''
    cp ${./meson.build} meson.build
  '';

  inherit (hyprland) nativeBuildInputs;

  buildInputs = [hyprland] ++ hyprland.buildInputs;

  meta = with lib; {
    homepage = "https://github.com/zakk4223/hyprNStack";
    description = "Hyprland HyprNStack Plugin";
    maintainers = with maintainers; [iynaix];
    platforms = platforms.linux;
  };
}
