{
  lib,
  installShellFiles,
  makeWrapper,
  pkg-config,
  glib,
  gexiv2,
  rustPlatform,
  czkawka,
  pqiv,
  rsync,
  rclip,
  useDedupe ? false,
  useRclip ? false,
  useWallfacer ? false,
}:
rustPlatform.buildRustPackage {
  pname = "dotfiles-rs";
  version = "0.1.0";

  src = ./.;

  cargoLock.lockFile = ./Cargo.lock;

  buildNoDefaultFeatures = true;
  buildFeatures =
    lib.optionals useRclip [ "rclip" ]
    ++ lib.optionals useWallfacer [ "wallfacer" ]
    ++ lib.optionals useDedupe [ "dedupe" ];

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

  postInstall = # sh
    ''
      for prog in wm-monitors wm-same-class rofi-mpv; do
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
    ''
      wrapProgram $out/bin/wallpaper --prefix PATH : ${
        lib.makeBinPath (
          [
            pqiv
            rsync
          ]
          ++ lib.optionals useDedupe [ czkawka ]
          ++ lib.optionals useRclip [ rclip ]
        )
      }
    '';

  meta = {
    description = "Utilities for iynaix's dotfiles";
    homepage = "https://github.com/iynaix/dotfiles";
    license = lib.licenses.mit;
    maintainers = [ lib.maintainers.iynaix ];
  };
}
