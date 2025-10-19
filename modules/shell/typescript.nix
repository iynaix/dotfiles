{
  flake.nixosModules.core = _: {
    custom.persist = {
      home = {
        cache.directories = [ ".cache/yarn" ];
      };
    };
  };
}
