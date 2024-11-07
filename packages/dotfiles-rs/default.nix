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

  cargoBuildFlags =
    [
      "--workspace"
      "--no-default-features"
    ]
    ++ lib.optionals useRclip [
      "--features"
      "rclip"
    ]
    ++ lib.optionals useWallfacer [
      "--features"
      "wallfacer"
    ]
    ++ lib.optionals useDedupe [
      "--features"
      "dedupe"
    ];

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

  postInstall = ''
    for prog in hypr-monitors hypr-same-class rofi-mpv; do
      installShellCompletion --cmd $prog \
        --bash <($out/bin/$prog --generate bash) \
        --fish <($out/bin/$prog --generate fish) \
        --zsh <($out/bin/$prog --generate zsh)
    done

    # wallpaper generate is a subcommand
    for prog in wallpaper; do
      installShellCompletion --cmd $prog \
        --bash <($out/bin/$prog generate bash) \
        --fish <($out/bin/$prog generate fish) \
        --zsh <($out/bin/$prog generate zsh)
    done
  '';

  postFixup = ''
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

  meta = with lib; {
    description = "Utilities for iynaix's dotfiles";
    homepage = "https://github.com/iynaix/dotfiles";
    license = licenses.mit;
    maintainers = [ maintainers.iynaix ];
  };
}
