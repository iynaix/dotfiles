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
  wm ? "hyprland",
  useDedupe ? false,
  useRclip ? false,
  useWallfacer ? false,
}:
assert lib.assertOneOf "dotfiles-rs wm" wm [
  "hyprland"
  "niri"
];
rustPlatform.buildRustPackage {
  pname = "dotfiles-${wm}";
  version = "0.9.0";

  src = ./.;

  cargoLock.lockFile = ./Cargo.lock;

  buildNoDefaultFeatures = true;
  buildFeatures =
    lib.optionals (wm == "hyprland") [ "hyprland" ]
    ++ lib.optionals (wm == "niri") [ "niri" ]
    ++ lib.optionals useRclip [ "rclip" ]
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

  postInstall =
    let
      progs =
        [
          "wm-same-class"
          "rofi-mpv"
        ]
        ++ lib.optionals (wm == "hyprland") [ "hypr-monitors" ]
        ++ lib.optionals (wm == "niri") [ ];
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
