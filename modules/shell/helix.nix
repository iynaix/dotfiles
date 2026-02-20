{ inputs, ... }:
{
  perSystem =
    { pkgs, ... }:
    let
      tomlFormat = pkgs.formats.toml { };
      helixConf = {
        theme = "tokyonight";
      };
    in
    {
      packages.helix = inputs.wrappers.lib.wrapPackage {
        inherit pkgs;
        package = pkgs.helix;
        flags = {
          "--config" = tomlFormat.generate "config.toml" helixConf;
        };
      };
    };

  flake.nixosModules.helix =
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
        helix = /* sh */ ''cat "${pkgs.helix.flags."--config"}"'';
      };
    };
}
