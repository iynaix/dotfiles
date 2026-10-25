{ inputs, pkgs, ... }:
let
  jujutsu' = inputs.wrappers.wrappers.jujutsu.wrap {
    inherit pkgs;
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
in
{
  environment.systemPackages = [
    jujutsu'
  ];

  custom.programs.print-config = {
    jj = /* sh */ ''moor --lang toml "${jujutsu'.configuration.constructFiles.generatedConfig.outPath}"'';
  };
}
