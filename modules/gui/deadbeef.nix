{
  flake.modules.nixos.core =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib) mkEnableOption mkIf;
    in
    {
      options.custom = {
        programs.deadbeef.enable = mkEnableOption "deadbeef";
      };

      config = mkIf config.custom.programs.deadbeef.enable {
        environment.systemPackages = [ pkgs.deadbeef ];

        custom.persist = {
          home.directories = [ ".config/deadbeef" ];
        };
      };
    };
}
