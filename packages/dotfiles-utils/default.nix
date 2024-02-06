{
  lib,
  installShellFiles,
  rustPlatform,
}:
rustPlatform.buildRustPackage {
  pname = "dotfiles-utils";
  version = "0.1.0";

  src = ./.;

  cargoLock.lockFile = ../../Cargo.lock;

  # create files for shell autocomplete
  nativeBuildInputs = [ installShellFiles ];

  # https://nixos.org/manual/nixpkgs/stable/#compiling-rust-applications-with-cargo
  # see section "Importing a cargo lock file"
  postPatch = ''
    ln -s ${../../Cargo.lock} Cargo.lock
  '';

  # installShellCompletion $releaseDir/build/dotfiles_utils-*/out/*.{bash,fish}
  preFixup = ''
    OUT_DIR=$releaseDir/build/dotfiles_utils-*/out

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
