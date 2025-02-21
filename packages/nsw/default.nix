{
  git,
  nh,
  lib,
  stdenvNoCC,
  makeWrapper,
  # variables
  dots ? "$HOME/projects/dotfiles",
  name ? "nsw",
  host ? "desktop",
}:
stdenvNoCC.mkDerivation {
  inherit name;
  version = "1.0";

  src = ./.;

  nativeBuildInputs = [ makeWrapper ];

  postPatch = # sh
    ''
      substituteInPlace nsw.sh \
        --replace-fail "@dots@" "${dots}" \
        --replace-fail "@host@" "${host}"
    '';

  postInstall = # sh
    ''
      install -D ./nsw.sh $out/bin/nsw

      wrapProgram $out/bin/nsw \
        --prefix PATH : ${
          lib.makeBinPath [
            git
            nh
          ]
        }
    '';

  meta = {
    description = "nh wrapper";
    license = lib.licenses.mit;
    maintainers = [ lib.maintainers.iynaix ];
    platforms = lib.platforms.linux;
  };
}
