{
  flake.modules.nixos.helix =
    { pkgs, ... }:
    let
      tomlFormat = pkgs.formats.toml { };
      helixConf = {
        theme = "tokyonight";
      };
    in
    {
      custom.wrappers = [
        (_: _prev: {
          helix = {
            flags = {
              "--config" = tomlFormat.generate "config.toml" helixConf;
            };
          };
        })
      ];

      environment.systemPackages = [ pkgs.helix ];
    };
}
