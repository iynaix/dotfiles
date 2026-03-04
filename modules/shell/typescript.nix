{
  flake.modules.nixos.core = _: {
    custom.persist = {
      home = {
        cache.directories = [ ".cache/yarn" ];
      };
    };
  };
}
