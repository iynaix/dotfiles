{
  enabled = false;

  packages =
    { inputs, pkgs, ... }:
    {
      helix = inputs.wrappers.wrappers.helix.wrap {
        inherit pkgs;
        package = pkgs.helix;
        settings = {
          theme = "tokyonight";
        };
      };
    };

  config =
    { pkgs, ... }:
    {
      nixpkgs.overlays = [
        (_: _prev: {
          helix = pkgs.custom.helix;
        })
      ];

      environment.systemPackages = [
        pkgs.helix # overlay-ed above
      ];

      custom.programs.print-config = {
        helix = /* sh */ ''moor "${pkgs.helix.configuration.constructFiles.config.outPath}"'';
      };
    };
}
