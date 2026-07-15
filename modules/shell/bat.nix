{
  inputs,
  lib,
  ...
}:
{
  perSystem =
    { pkgs, ... }:
    {
      packages = rec {
        bat = inputs.wrappers.lib.wrapPackage {
          inherit pkgs;
          package = pkgs.bat;
          flags = {
            "--theme" = "base16";
            "--style" = "grid";
          };

          runtimePkgs = [
            batman
          ];

          # TODO: re-enable when https://github.com/BirdeeHub/nix-wrapper-modules/pull/583 is merged
          # passthru.abbreviations = {
          #   "--help" = {
          #     expansion = "--help | bat --plain --language=help";
          #     position = "anywhere";
          #   };
          # };
        };

        # batman with completions
        batman = pkgs.bat-extras.batman.overrideAttrs (o: {
          postInstall =
            (o.postInstall or "")
            # sh
            + ''
              mkdir -p $out/share/bash-completion/completions
              echo 'complete -F _comp_cmd_man batman' > $out/share/bash-completion/completions/batman

              mkdir -p $out/share/fish/vendor_completions.d
              echo 'complete batman --wraps man' > $out/share/fish/vendor_completions.d/batman.fish

              mkdir -p $out/share/zsh/site-functions
              cat << EOF > $out/share/zsh/site-functions/_batman
              #compdef batman
              _man "$@"
              EOF
            '';
        });
      };
    };

  flake.modules.nixos.core =
    { pkgs, ... }:
    {
      nixpkgs.overlays = [
        (_: _prev: {
          bat = pkgs.custom.bat;
        })
      ];

      environment.systemPackages = [
        pkgs.bat # overlay-ed above
        pkgs.custom.batman
      ];

      custom.programs.print-config = {
        bat = /* sh */ ''moor --lang sh "${lib.getExe pkgs.bat}"'';
      };
    };
}
