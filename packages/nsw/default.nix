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
  specialisation ? "",
}:
stdenvNoCC.mkDerivation {
  name = "${name}-${specialisation}";
  version = "1.0";

  src = ./.;

  nativeBuildInputs = [ makeWrapper ];

  postPatch = # sh
    ''
      substituteInPlace nsw.sh \
        --replace-fail "@dots@" "${dots}" \
        --replace-fail "@host@" "${host}" \
        --replace-fail "@specialisation@" "${specialisation}"
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
