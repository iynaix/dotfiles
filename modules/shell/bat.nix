{ inputs, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      packages = {
        bat' = inputs.wrappers.lib.wrapPackage {
          inherit pkgs;
          package = pkgs.bat;
          flags = {
            "--theme" = "base16";
            "--style" = "grid";
          };
        };
        # batman with completions
        batman' = pkgs.bat-extras.batman.overrideAttrs (o: {
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

  flake.nixosModules.core =
    { pkgs, self, ... }:
    {
      nixpkgs.overlays = [
        (_: _prev: {
          bat = self.packages.${pkgs.stdenv.hostPlatform.system}.bat';
        })
      ];

      environment.systemPackages = [
        pkgs.bat # overlay-ed above
        self.packages.${pkgs.stdenv.hostPlatform.system}.batman'
      ];

      programs = {
        # manually add the abbr so it doesn't get mangled by nix
        fish.interactiveShellInit = /* fish */ ''
          abbr -a --position anywhere -- --help '--help | bat --plain --language=help'
        '';
      };
    };
}
