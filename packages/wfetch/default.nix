{dotfiles-utils}:
(dotfiles-utils.override {waifu = false;})
.overrideAttrs (o: {
  # only build wfetch
  cargoBuildFlags = o.cargoBuildFlags ++ ["--bin" "wfetch"];

  preFixup = ''
    OUT_DIR=$releaseDir/build/dotfiles_utils-*/out

    installShellCompletion --bash $OUT_DIR/wfetch.bash
    installShellCompletion --fish $OUT_DIR/wfetch.fish
    installShellCompletion --zsh $OUT_DIR/_wfetch
  '';

  meta =
    o.meta
    // {
      mainProgram = "wfetch";
    };
})
