{
  config =
    {
      inputs,
      lib,
      pkgs,
      system,
      user,
      ...
    }:
    {
      imports = [
        inputs.hjem.nixosModules.default
        # alias for hjem
        (lib.mkAliasOptionModule [ "hj" ] [ "hjem" "users" user ])
      ];

      config = {
        environment.systemPackages =
          assert lib.assertMsg (!(pkgs ? "hjem")) "hjem package is now in nixpkgs";
          [
            inputs.hjem.packages.${system}.hjem
          ];

        hjem = {
          # thanks for not fucking wasting my time
          clobberByDefault = true;
        };
      };
    };
}
