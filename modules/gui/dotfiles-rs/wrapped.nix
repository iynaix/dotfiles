{
  packages =
    { pkgs, ... }:
    let
      drv =
        {
          lib,
          callPackage,
          stdenv,
          makeWrapper,
          procps,
          czkawka,
          swayimg,
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
                      procps
                      rclip
                      rsync
                      wlr-randr
                      swayimg
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
      dotfiles-rs = pkgs.callPackage drv { };
    };
}
