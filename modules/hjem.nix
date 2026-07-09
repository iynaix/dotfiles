{ inputs, ... }:
{
  flake.modules.nixos.core =
    { config, pkgs, ... }:
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
          linker = inputs.hjem.packages.${pkgs.stdenv.hostPlatform.system}.smfh;
        };
      };
    };
}
