{
  lib,
  fetchFromGitHub,
  gcc13Stdenv,
  hyprland,
}:
gcc13Stdenv.mkDerivation {
  pname = "hyprNStack";
  version = "${hyprland.version}-unstable-2024-03-27";

  src = fetchFromGitHub {
    owner = "zakk4223";
    repo = "hyprNStack";
    rev = "9a46b8adf2ecc67c47b1db75ffb832de3aed1291";
    hash = "sha256-g8PG9Hg3qBBDlPA2rT/Luzes1+rEVGtfU/S8amXt3Hk=";
  };

  preConfigure = ''
    cp ${./meson.build} meson.build
  '';

  inherit (hyprland) nativeBuildInputs;

  buildInputs = [ hyprland ] ++ hyprland.buildInputs;

  meta = with lib; {
    homepage = "https://github.com/zakk4223/hyprNStack";
    description = "Hyprland HyprNStack Plugin";
    maintainers = with maintainers; [ iynaix ];
    platforms = platforms.linux;
  };
}
