{
  lib,
  fetchFromGitHub,
  gcc13Stdenv,
  hyprland,
}:
gcc13Stdenv.mkDerivation {
  pname = "hyprNStack";
  version = "${hyprland.version}-unstable-2024-04-13";

  src = fetchFromGitHub {
    owner = "zakk4223";
    repo = "hyprNStack";
    rev = "cdde5e302f66fba2be05195cd634f74ef464dd8f";
    hash = "sha256-fOvhWrmkyYd2iCbThMclX0RpmRlJva2pzH8Ymtl11WA=";
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
