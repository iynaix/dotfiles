{
  lib,
  installShellFiles,
  pkg-config,
  glib,
  gexiv2,
  rustPlatform,
}:
rustPlatform.buildRustPackage {
  pname = "dotfiles-rs";
  version = "0.1.0";

  src = ./.;

  cargoLock.lockFile = ./Cargo.lock;

  cargoBuildFlags = [ "--workspace" ];

  # create files for shell autocomplete
  nativeBuildInputs = [
    installShellFiles
    pkg-config
  ];

  buildInputs = [
    glib
    gexiv2 # for reading metadata
  ];

  postInstall = ''
    for prog in hypr-monitors hypr-same-class rofi-mpv wallpaper; do
      installShellCompletion --cmd $prog \
        --bash <($out/bin/$prog --generate bash) \
        --fish <($out/bin/$prog --generate fish) \
        --zsh <($out/bin/$prog --generate zsh)
    done
  '';

  meta = with lib; {
    description = "Utilities for iynaix's dotfiles";
    homepage = "https://github.com/iynaix/dotfiles";
    license = licenses.mit;
    maintainers = [ maintainers.iynaix ];
  };
}
