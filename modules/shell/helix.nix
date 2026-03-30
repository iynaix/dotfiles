{ inputs, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      packages.helix = inputs.wrappers.wrappers.helix.wrap {
        inherit pkgs;
        package = pkgs.helix;
        settings = {
          theme = "tokyonight";
        };
      };
    };

  flake.modules.nixos.programs_helix =
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
