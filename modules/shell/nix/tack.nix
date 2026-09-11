{ pkgs, ... }:
{
  programs.tack = {
    enable = true;
    package = pkgs.tack.overrideAttrs (_o: {
      # add --exclude argument for tack upgrade
      src = pkgs.fetchFromGitHub {
        owner = "manic-systems";
        repo = "tack";
        rev = "d9c0516ff654c8a48dd4294dd183db51154ffad2";
        hash = "sha256-GxJX6df+SqpZv3fkH+5oLQOVT/wI5CovnMaGGhtpvT0=";
      };
    });
    nixConfTokens = true; # use GITHUB_TOKEN
  };
}
