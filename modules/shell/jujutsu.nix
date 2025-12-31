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
      jujutsuToml = tomlFormat.generate "config.toml" jujutsuConf;
    in
    {
      nixpkgs.overlays = [
        (_: prev: {
          # doesn't make sense to expose with user details
          jujutsu' = inputs.wrappers.lib.wrapPackage {
            pkgs = prev;
            package = prev.jujutsu;
            flags = {
              "--config-file" = toString jujutsuToml;
            };
          };
        })
      ];

      environment.systemPackages = [
        pkgs.jujutsu # overlay-ed above
      ];

      custom.programs.print-config = {
        jujutsu = /* sh */ ''cat "${toString jujutsuToml}"'';
      };
    };
}
