{ pkgs, ... }:
{
  programs.tack = {
    enable = true;
    package = pkgs.tack.overrideAttrs (_o: rec {
      # add --exclude argument for tack upgrade
      src = pkgs.fetchFromGitHub {
        owner = "manic-systems";
        repo = "tack";
        rev = "4aaed84df55c1f116ccd81d7bc0fb818a068955f";
        hash = "sha256-5fc6+wvlE5yUPkrbgi9xSWsaVRA54qLuMot4sCoLm2E=";
      };

      cargoDeps = pkgs.rustPlatform.importCargoLock {
        lockFile = "${src}/Cargo.lock";
        allowBuiltinFetchGit = true;
      };
    });
    nixConfTokens = true; # use GITHUB_TOKEN
  };
}
