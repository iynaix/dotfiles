{dotfiles-utils}:
(dotfiles-utils.override {waifu = false;})
.overrideAttrs (o: {
  # only build wfetch
  cargoBuildFlags = o.cargoBuildFlags ++ ["--bin" "wfetch"];

  preFixup = ''
    installShellCompletion $releaseDir/build/dotfiles_utils-*/out/wfetch.{bash,fish}
  '';

  meta =
    o.meta
    // {
      mainProgram = "wfetch";
    };
})
