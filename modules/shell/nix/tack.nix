{ inputs, system, ... }:
{
  programs.tack = {
    enable = true;
    package = inputs.tack.packages.${system}.default;
    nixConfTokens = true; # use GITHUB_TOKEN
  };
}
