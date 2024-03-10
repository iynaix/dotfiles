{
  lib,
  fetchFromGitHub,
  gcc13Stdenv,
  hyprland,
}:
gcc13Stdenv.mkDerivation {
  pname = "hyprNStack";
  version = "${hyprland.version}-unstable-2024-02-29";

  src = fetchFromGitHub {
    owner = "zakk4223";
    repo = "hyprNStack";
    rev = "9bf059b8322df6fbcc918a17655fc22e308bd27a";
    hash = "sha256-1E4w4/ng+0felBMtVWzczxo7GxU87GODiriVbvmue7Q=";
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
