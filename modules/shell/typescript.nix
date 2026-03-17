{
  flake.modules.nixos.core = _: {
    environment.variables = {
      npm_config_cache = "$HOME/.cache/npm";
    };

    custom.persist = {
      home = {
        cache.directories = [
          ".cache/npm"
          ".cache/pnpm"
          ".cache/yarn"
        ];
      };
    };
  };
}
