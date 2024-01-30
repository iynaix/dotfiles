{
  rustPlatform,
  dotfiles-utils,
}:
(dotfiles-utils.override {
  # use rust from nixpkgs instead
  inherit rustPlatform;
})
.overrideAttrs (o: {
  # only build waifufetch
  cargoBuildFlags = ["--bin" "waifufetch"];

  preFixup = ''
    installShellCompletion $releaseDir/build/dotfiles_utils-*/out/waifufetch.{bash,fish}
  '';

  meta =
    o.meta
    // {
      mainProgram = "waifufetch";
    };
})
