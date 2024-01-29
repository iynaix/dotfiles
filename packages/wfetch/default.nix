{
  rustPlatform,
  dotfiles-utils,
}:
(dotfiles-utils.override {
  # use rust from nixpkgs instead
  inherit rustPlatform;
})
.overrideAttrs (o: {
  # only build wfetch
  cargoBuildFlags = ["--bin" "wfetch"];

  preFixup = ''
    installShellCompletion $releaseDir/build/dotfiles_utils-*/out/wfetch.{bash,fish}
  '';

  meta =
    o.meta
    // {
      mainProgram = "wfetch";
    };
})
