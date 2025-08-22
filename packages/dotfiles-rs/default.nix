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
  wm ? "hyprland",
  useDedupe ? false,
  useRclip ? false,
  useWallfacer ? false,
}:
assert lib.assertOneOf "dotfiles-rs wm" wm [
  "hyprland"
  "niri"
  "mango"
];
rustPlatform.buildRustPackage {
  pname = "dotfiles-${wm}";
  version = "0.9.0";

  src = ./.;

  cargoLock = {
    lockFile = ./Cargo.lock;
    # TODO: remove when new version of niri-ipc is released and git version is no longer used in Cargo.toml
    allowBuiltinFetchGit = true;
  };

  buildNoDefaultFeatures = true;
  buildFeatures =
    lib.optionals (wm == "hyprland") [ "hyprland" ]
    ++ lib.optionals (wm == "niri") [ "niri" ]
    ++ lib.optionals (wm == "mango") [ "mango" ]
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
      progs = [
        "wm-same-class"
        "rofi-mpv"
      ]
      ++ lib.optionals (wm == "hyprland") [ "hypr-monitors" ]
      ++ lib.optionals (wm == "niri") [ "niri-resize-workspace" ];
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
        "wallpaper"
      ]
      ++ lib.optionals (wm == "niri") [ "niri-ipc" ];
    in
    ''
      for prog in ${toString progs}; do
        wrapProgram $out/bin/$prog --prefix PATH : ${
          lib.makeBinPath (
            [
              dconf
              procps
              pqiv
              rsync
              wallust
              swww
              wlr-randr
            ]
            ++ lib.optionals useDedupe [ czkawka ]
            ++ lib.optionals useRclip [ rclip ]
          )
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
