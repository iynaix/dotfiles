{
  flake.modules.nixos.core = {
    programs.tack = {
      enable = true;
      nixConfTokens = true; # use GITHUB_TOKEN
    };
  };
}
