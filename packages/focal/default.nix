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
  tesseract5,
  ocr ? false,
}:
rustPlatform.buildRustPackage {
  pname = "focal";
  version = "0.1.0";

  inherit src;

  cargoLock.lockFile = ../../Cargo.lock;

  cargoBuildFlags = [ "-p focal" ];

  nativeBuildInputs = [
    installShellFiles
    makeWrapper
  ];

  postInstall = ''
    installShellCompletion --cmd focal \
      --bash <($out/bin/focal --generate-completions bash) \
      --fish <($out/bin/focal --generate-completions fish) \
      --zsh <($out/bin/focal --generate-completions zsh)
  '';

  postFixup =
    let
      binaries = [
        grim
        libnotify
        slurp
        wl-clipboard
        hyprland
        rofi
        swappy
      ] ++ lib.optional ocr tesseract5;
    in
    "wrapProgram $out/bin/focal --prefix PATH : ${lib.makeBinPath binaries}";

  meta = with lib; {
    description = "Rofi menu for screenshots / screencasts";
    mainProgram = "focal";
    homepage = "https://github.com/iynaix/dotfiles";
    license = licenses.mit;
    maintainers = [ maintainers.iynaix ];
  };
}
