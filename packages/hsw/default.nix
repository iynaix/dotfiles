{
  git,
  nh,
  lib,
  stdenvNoCC,
  makeWrapper,
  # variables
  dots ? "$HOME/projects/dotfiles",
  name ? "hsw",
  host ? "desktop",
}:
stdenvNoCC.mkDerivation {
  inherit name;
  version = "1.0";

  src = ./.;

  nativeBuildInputs = [ makeWrapper ];

  postPatch = ''
    substituteInPlace hsw.sh \
      --replace-fail "@dots@" "${dots}" \
      --replace-fail "@host@" "${host}"
  '';

  postInstall = ''
    install -D ./hsw.sh $out/bin/hsw

    wrapProgram $out/bin/hsw \
      --prefix PATH : ${
        lib.makeBinPath [
          git
          nh
        ]
      }
  '';

  meta = {
    description = "Switch to a different home-manager configuration";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ iynaix ];
    platforms = lib.platforms.linux;
  };
}
