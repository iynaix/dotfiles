{
  src,
  lib,
  # installShellFiles,
  rustPlatform,
}:
rustPlatform.buildRustPackage {
  pname = "rofi-capture";
  version = "0.1.0";

  inherit src;

  cargoLock.lockFile = ../../Cargo.lock;

  cargoBuildFlags = [ "-p rofi-capture" ];

  # create files for shell autocomplete
  # nativeBuildInputs = [ installShellFiles ];

  # installShellCompletion $releaseDir/build/dotfiles-*/out/*.{bash,fish}
  # preFixup = ''
  #   OUT_DIR=$releaseDir/build/dotfiles-*/out

  #   installShellCompletion --bash $OUT_DIR/*.bash
  #   installShellCompletion --fish $OUT_DIR/*.fish
  #   installShellCompletion --zsh $OUT_DIR/_*
  # '';

  meta = with lib; {
    description = "Rofi menu for screenshots / screencasts";
    homepage = "https://github.com/iynaix/dotfiles";
    license = licenses.mit;
    maintainers = [ maintainers.iynaix ];
  };
}
