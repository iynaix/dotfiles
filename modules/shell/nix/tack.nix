{
  flake.modules.nixos.core =
    { pkgs, ... }:
    {
      # use unmerged tack PR
      nixpkgs-patcher = {
        settings.patches = [
          # tack package
          # https://github.com/NixOS/nixpkgs/pull/533815
          (pkgs.fetchpatch {
            url = "https://github.com/NixOS/nixpkgs/commit/3660e2c77e96f8ea81249d3ef2dddd3c0344ebe9.patch";
            hash = "sha256-n9s9vQ1FJkAysi5KFpfckeYBmAyYrq4MYB+3hA6AArI=";
          })
          # tack module
          # https://github.com/NixOS/nixpkgs/pull/533815
          (pkgs.fetchpatch {
            url = "https://github.com/NixOS/nixpkgs/commit/6e43704f0867ebdf35e1bd026075fadb28066cb7.patch";
            hash = "sha256-pdsttm0mBS3jG9rFJCKncwL8GQLvlwt0Qo1SXWxIvfI=";
          })
        ];
      };

      programs.tack = {
        enable = true;
        nixConfTokens = true; # use GITHUB_TOKEN
      };
    };
}
