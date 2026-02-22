# patches to be applied to nixpkgs
{
  flake.nixosModules.core =
    { pkgs, ... }:
    {
      nixpkgs-patcher = {
        enable = true;

        settings.patches = [
          # orca-slicer 2.3.2-dev
          # https://github.com/NixOS/nixpkgs/pull/480799
          ./orca-slicer-2.3.2.patch

          # ly: 1.3.1 -> 1.3.2
          # https://github.com/NixOS/nixpkgs/pull/487644
          (pkgs.fetchurl {
            url = "https://github.com/NixOS/nixpkgs/pull/487644/commits/51f80dff2cd26941b456a97fe80631bdbcdbffa1.patch";
            hash = "sha256-bXQ1t1SnTZbUp9NCejbFRpzbBYV2zL04fUHCL9zRI3o=";
          })

          # actually import the mangowc module
          # remove when https://github.com/NixOS/nixpkgs/pull/484963 is merged
          (pkgs.fetchurl {
            url = "https://github.com/NixOS/nixpkgs/commit/966fced4f13518621e9d6ed528d2617640c6f315.patch";
            hash = "sha256-+aBUfHygKzZZApYA4z8scMejymJVem45TNMp/9GDZkM=";
          })
        ];
      };
    };
}
