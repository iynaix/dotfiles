{
  lib,
  installShellFiles,
  makeWrapper,
  rustPlatform,
  ascii-image-converter,
  fastfetch,
  imagemagick,
  waifu ? true,
}:
rustPlatform.buildRustPackage {
  pname = "dotfiles-utils";
  version = "0.1.0";

  src = ./.;

  cargoLock.lockFile = ../../Cargo.lock;

  cargoBuildFlags =
    [
      "--no-default-features"
      "--features"
      "hyprland"
    ]
    ++ lib.optionals waifu ["--features" "wfetch-waifu"];

  # create files for shell autocomplete
  nativeBuildInputs = [installShellFiles makeWrapper];

  # https://nixos.org/manual/nixpkgs/stable/#compiling-rust-applications-with-cargo
  # see section "Importing a cargo lock file"
  postPatch = ''
    ln -s ${../../Cargo.lock} Cargo.lock
  '';

  postInstall = ''
    cp -r $src/assets $out
  '';

  preFixup = ''
    installShellCompletion $releaseDir/build/dotfiles_utils-*/out/*.{bash,fish}
  '';

  postFixup = ''
    wrapProgram $out/bin/wfetch \
      --prefix PATH : "${lib.makeBinPath [ascii-image-converter]}" \
      --prefix PATH : "${lib.makeBinPath [fastfetch]}" \
      --prefix PATH : "${lib.makeBinPath [imagemagick]}"
  '';

  meta = with lib; {
    description = "Utilities for iynaix's dotfiles";
    homepage = "https://github.com/iynaix/dotfiles";
    license = licenses.mit;
    maintainers = [maintainers.iynaix];
  };
}
