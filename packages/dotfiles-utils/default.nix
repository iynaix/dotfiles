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

  # https://nixos.org/manual/nixpkgs/stable/#compiling-rust-applications-with-cargo
  # see section "Importing a cargo lock file"
  postPatch = ''
    ln -s ${../../Cargo.lock} Cargo.lock
  '';

  # create files for shell autocomplete
  nativeBuildInputs = [installShellFiles];

  preFixup = ''
    installShellCompletion $releaseDir/build/dotfiles_utils-*/out/*.{bash,fish}
  '';

  meta = with lib; {
    description = "Utilities for iynaix's dotfiles";
    homepage = "https://github.com/iynaix/dotfiles";
    license = licenses.mit;
    maintainers = [maintainers.iynaix];
  };
}
