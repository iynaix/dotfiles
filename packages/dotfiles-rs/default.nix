{
  lib,
  installShellFiles,
  makeWrapper,
  pkg-config,
  glib,
  gexiv2,
  rustPlatform,
  dconf,
  procps,
  czkawka,
  pqiv,
  rsync,
  rclip,
  swww,
  wallust,
  wlr-randr,
}:
rustPlatform.buildRustPackage {
  pname = "dotfiles-rs";
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
      progs = [
        "hypr-monitors"
        "niri-resize-workspace"
        "wm-same-class"
      ];
    in
    ''
      for prog in ${toString progs}; do
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

  postFixup = # sh
    let
      progs = [
        "hypr-ipc"
        "hypr-monitors"
        "niri-ipc"
        "wallpaper"
      ];
    in
    ''
      for prog in ${toString progs}; do
        wrapProgram $out/bin/$prog --prefix PATH : ${
          lib.makeBinPath [
            czkawka
            dconf
            procps
            rclip
            rsync
            wallust
            swww
            wlr-randr
            pqiv
          ]
        }
      done
    '';

  meta = {
    description = "Utilities for iynaix's dotfiles";
    homepage = "https://github.com/iynaix/dotfiles";
    license = lib.licenses.mit;
    maintainers = [ lib.maintainers.iynaix ];
  };
}
