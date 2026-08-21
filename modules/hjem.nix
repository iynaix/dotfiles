{
  config =
    {
      inputs,
      lib,
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
        hjem = {
          # thanks for not fucking wasting my time
          clobberByDefault = true;
        };
      };
    };
}
