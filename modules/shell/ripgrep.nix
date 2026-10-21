{
  packages =
    { inputs, pkgs, ... }:
    {
      ripgrep = inputs.wrappers.wrappers.ripgrep.wrap {
        inherit pkgs;

        ignores = ''
          .envrc
          .direnv
          .devenv
          .ignore
          *.lock
        '';

        settings = {
          smart-case = true;
        };
      };
    };

  config =
    { pkgs, ... }:
    {
      nixpkgs.overlays = [
        (_: _prev: {
          inherit (pkgs.custom) ripgrep;
        })
      ];

      environment.systemPackages = [
        pkgs.ripgrep # overlay-ed above
      ];

      custom.programs.print-config = rec {
        rg = /* sh */ "moor ${pkgs.ripgrep.configuration.constructFiles.renderedSettings.outPath}";
        ripgrep = rg;
      };
    };
}
