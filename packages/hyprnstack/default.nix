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
    rev = "659ce780c6c826cffd8f7f24b0b025985099e2af";
    sha256 = "sha256-XZCHnpRSShtZ8vp4Dg0q92jNlg2+DgxLkcWns5bdWIM=";
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
