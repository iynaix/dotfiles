# the flake assumes usage of the hyprland flake and is not easily overridable
{
  lib,
  gcc14Stdenv,
  hyprland,
  fetchFromGitHub,
  pkg-config,
}:
gcc14Stdenv.mkDerivation rec {
  pname = "hypr-darkwindow";
  version = "0.48.1";

  src = fetchFromGitHub {
    owner = "micha4w";
    repo = "Hypr-DarkWindow";
    rev = "v${version}";
    hash = "sha256-34itqDO1NPPs5c8tNHOf4SRbUIFucFgkWNv6x5ZheSs=";
  };

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ hyprland.dev ] ++ hyprland.buildInputs;

  installPhase = ''
    mkdir -p $out/lib
    install ./out/hypr-darkwindow.so $out/lib/libhypr-darkwindow.so
  '';

  meta = {
    description = "Hyprland Plugin to invert Colors of specific Windows";
    homepage = "https://github.com/micha4w/Hypr-DarkWindow";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ iynaix ];
    mainProgram = "hypr-darkwindow";
    platforms = lib.platforms.all;
  };
}
