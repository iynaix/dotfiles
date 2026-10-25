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
      environment.systemPackages = [
        pkgs.custom.ripgrep
      ];

      custom.programs.print-config = rec {
        rg = /* sh */ "moor ${pkgs.custom.ripgrep.configuration.constructFiles.renderedSettings.outPath}";
        ripgrep = rg;
      };
    };
}
