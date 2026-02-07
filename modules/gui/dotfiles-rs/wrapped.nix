{
  perSystem =
    { pkgs, ... }:
    let
      drv =
        {
          lib,
          callPackage,
          stdenv,
          makeWrapper,
          dconf,
          procps,
          czkawka,
          pqiv,
          rsync,
          rclip,
          wlr-randr,
          extraPackages ? [ ],
        }:
        let
          dotfiles-rs-unwrapped = callPackage ./_unwrapped.nix { };
        in
        stdenv.mkDerivation {
          # wrapped in a separate derivation for faster building
          pname = "dotfiles-rs";
          inherit (dotfiles-rs-unwrapped) version;

          preferLocalBuild = true;

          nativeBuildInputs = [
            makeWrapper
          ];

          buildCommand = /* sh */ ''
            for bin in ${dotfiles-rs-unwrapped}/bin/*; do
                makeWrapper "$bin" "$out/bin/$(basename "$bin")" --prefix PATH : ${
                  lib.makeBinPath (
                    [
                      czkawka
                      dconf
                      procps
                      rclip
                      rsync
                      wlr-randr
                      pqiv
                    ]
                    ++ extraPackages
                  )
                }
            done
          '';

          passthru.unwrapped = dotfiles-rs-unwrapped;

          inherit (dotfiles-rs-unwrapped) meta;
        };
    in
    {
      packages.dotfiles-rs = pkgs.callPackage drv { };
    };
}
