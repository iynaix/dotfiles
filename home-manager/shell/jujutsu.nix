_: {
  programs = {
    git.ignores = [ ".jj" ];
    jujutsu = {
      enable = true;
      settings.user = {
        email = "pilum-murialis.toge@proton.me";
        name = "Elias Ainsworth";
      };
    };
  };
}
