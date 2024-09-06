{
  src,
  lib,
  installShellFiles,
  rustPlatform,
  makeWrapper,
  rofi,
  grim,
  libnotify,
  slurp,
  swappy,
  wl-clipboard,
  hyprland,
}:
rustPlatform.buildRustPackage {
  pname = "rofi-capture";
  version = "0.1.0";

  inherit src;

  cargoLock.lockFile = ../../Cargo.lock;

  cargoBuildFlags = [ "-p rofi-capture" ];

  nativeBuildInputs = [
    installShellFiles
    makeWrapper
  ];

  postInstall = ''
    installShellCompletion --cmd rofi-capture \
      --bash <($out/bin/rofi-capture --generate-completions bash) \
      --fish <($out/bin/rofi-capture --generate-completions fish) \
      --zsh <($out/bin/rofi-capture --generate-completions zsh)
  '';

  postFixup = ''
    wrapProgram $out/bin/rofi-capture \
      --prefix PATH : ${
        lib.makeBinPath [
          grim
          libnotify
          slurp
          wl-clipboard
          hyprland
          rofi
          swappy
        ]
      }
  '';

  meta = with lib; {
    description = "Rofi menu for screenshots / screencasts";
    homepage = "https://github.com/iynaix/dotfiles";
    license = licenses.mit;
    maintainers = [ maintainers.iynaix ];
  };
}
