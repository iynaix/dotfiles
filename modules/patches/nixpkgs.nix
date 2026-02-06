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

          # actually import the mangowc module
          # remove when https://github.com/NixOS/nixpkgs/pull/484963 is merged
          (pkgs.fetchurl {
            url = "https://github.com/NixOS/nixpkgs/commit/966fced4f13518621e9d6ed528d2617640c6f315.patch";
            hash = "sha256-ZN55kHhhmwfjZ2QLG00AjGbDV7f7ZRAKD0Fs/sMDUXA=";
          })
        ];
      };
    };
}
