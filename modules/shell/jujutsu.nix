{ pkgs, ... }:
let
  toJujutsuConf = pkgs.formats.toml { };
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
  custom.wrappers = [
    (
      { pkgs, ... }:
      {
        wrappers.jujutsu = {
          basePackage = pkgs.jujutsu;
          prependFlags = [
            "--config-file"
            (toJujutsuConf.generate "helix-config" jujutsuConf)
          ];
        };
      }
    )
  ];

  environment.systemPackages = [ pkgs.jujutsu ];
}
