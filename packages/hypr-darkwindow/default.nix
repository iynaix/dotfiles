# the flake assumes usage of the hyprland flake and is not easily overridable
{
  lib,
  gcc14Stdenv,
  hyprland,
  fetchFromGitHub,
  pkg-config,
}:
gcc14Stdenv.mkDerivation (finalAttrs: {
  pname = "hypr-darkwindow";
  version = "0.51.1";

  src = fetchFromGitHub {
    owner = "micha4w";
    repo = "Hypr-DarkWindow";
    rev = "v${finalAttrs.version}";
    hash = "sha256-jq5j459gCVuBOpuGEvXe+9/O+HAineFxQI4sIcEPi/c=";
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
})
