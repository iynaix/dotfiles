{
  flake.modules.nixos.core = { pkgs, ... }: {
    programs.tack = {
      enable = true;
      package = pkgs.tack.overrideAttrs (o: {
        patches = (o.patches or [ ]) ++ [
          # add --exclude argument for tack upgrade
          # https://github.com/manic-systems/tack/pull/86/
          (pkgs.fetchpatch {
            url = "https://github.com/manic-systems/tack/commit/7dcaeea2e048319b00e9e5081be65bfa5607d22f.patch";
            hash = "sha256-oNHuGLdtOrpxqqpfw/2j1D/3wEYFeJ0+sJ1rWzPc55g=";
          })
        ];
      });
      nixConfTokens = true; # use GITHUB_TOKEN
    };
  };
}
