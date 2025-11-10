{ inputs, ... }:
{
  flake.nixosModules.core =
    { pkgs, ... }:
    let
      tomlFormat = pkgs.formats.toml { };
      jujutsuConf = {
        user = {
          name = "iynaix";
          email = "iynaix@gmail.com";
        };
        template-aliases = {
          "format_short_id(id)" = "id.shortest()";
        };
      };
    in
    {
      nixpkgs.overlays = [
        (_: prev: {
          # doesn't make sense to expose with user details
          jujutsu' = inputs.wrappers.lib.wrapPackage {
            pkgs = prev;
            package = prev.jujutsu;
            flags = {
              "--config-file" = tomlFormat.generate "config.toml" jujutsuConf;
            };
          };
        })
      ];

      environment.systemPackages = [
        pkgs.jujutsu # overlay-ed above
      ];
    };
}
