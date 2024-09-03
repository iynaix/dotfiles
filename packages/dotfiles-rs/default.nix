{
  src,
  lib,
  installShellFiles,
  rustPlatform,
}:
rustPlatform.buildRustPackage {
  pname = "dotfiles-rs";
  version = "0.1.0";

  inherit src;

  cargoLock.lockFile = ../../Cargo.lock;

  cargoBuildFlags = [ "-p dotfiles" ];

  # create files for shell autocomplete
  nativeBuildInputs = [ installShellFiles ];

  preFixup = ''
    OUT_DIR=$releaseDir/build/dotfiles-*/out

    installShellCompletion --bash $OUT_DIR/*.bash
    installShellCompletion --fish $OUT_DIR/*.fish
    installShellCompletion --zsh $OUT_DIR/_*
  '';

  meta = with lib; {
    description = "Utilities for iynaix's dotfiles";
    homepage = "https://github.com/iynaix/dotfiles";
    license = licenses.mit;
    maintainers = [ maintainers.iynaix ];
  };
}
