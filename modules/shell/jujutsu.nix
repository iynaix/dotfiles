{ inputs, ... }:
{
  flake.modules.nixos.core =
    { pkgs, ... }:
    {
      nixpkgs.overlays = [
        (_: prev: {
          # doesn't make sense to expose with user details
          jujutsu = inputs.wrappers.wrappers.jujutsu.wrap {
            pkgs = prev;
            settings = {
              user = {
                name = "iynaix";
                email = "iynaix@gmail.com";
              };
              template-aliases = {
                "format_short_id(id)" = "id.shortest()";
              };
            };
          };
        })
      ];

      environment.systemPackages = [
        pkgs.jujutsu # overlay-ed above
      ];

      custom.programs.print-config = {
        jj = /* sh */ ''moor --lang toml "${pkgs.jujutsu.configuration.constructFiles.generatedConfig.outPath}"'';
      };
    };
}
