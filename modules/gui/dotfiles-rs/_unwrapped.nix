{
  lib,
  installShellFiles,
  makeWrapper,
  pkg-config,
  glib,
  gexiv2,
  rustPlatform,
}:
rustPlatform.buildRustPackage {
  pname = "dotfiles-rs-unwrapped";
  version = "0.9.0";

  src = ./.;

  cargoLock = {
    lockFile = ./Cargo.lock;
    # enable for niri-ipc git
    # allowBuiltinFetchGit = true;
  };

  # create files for shell autocomplete
  nativeBuildInputs = [
    installShellFiles
    makeWrapper
    pkg-config
  ];

  buildInputs = [
    glib
    gexiv2 # for reading metadata
  ];

  postInstall =
    let
      binsWithCompletions = [
        "hypr-monitors"
        "niri-resize-workspace"
        "wm-same-class"
      ];
    in
    /* sh */ ''
      for prog in ${toString binsWithCompletions}; do
        installShellCompletion --cmd $prog \
          --bash <($out/bin/$prog --generate bash) \
          --fish <($out/bin/$prog --generate fish) \
          --zsh <($out/bin/$prog --generate zsh)
      done
      installManPage dotfiles/target/man/*

      for prog in wallpaper; do
        installShellCompletion --cmd $prog \
          --bash <($out/bin/$prog generate bash) \
          --fish <($out/bin/$prog generate fish) \
          --zsh <($out/bin/$prog generate zsh)
      done
      installManPage wallpaper/target/man/*
    '';

  meta = {
    description = "Utilities for iynaix's dotfiles";
    homepage = "https://github.com/iynaix/dotfiles";
    license = lib.licenses.mit;
    maintainers = [ lib.maintainers.iynaix ];
  };
}
