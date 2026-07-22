{ inputs, ... }:
{
  flake.modules.nixos.core =
    { config, ... }:
    let
      inherit (config.custom.constants) user;
    in
    {
      imports = [
        inputs.hjem.nixosModules.default
        # alias for hjem
        (inputs.nixpkgs.lib.mkAliasOptionModule [ "hj" ] [ "hjem" "users" user ])
      ];

      config = {
        hjem = {
          # thanks for not fucking wasting my time
          clobberByDefault = true;
        };
      };
    };
}
