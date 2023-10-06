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
