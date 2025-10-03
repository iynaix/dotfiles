_: {
  environment.shellAliases = {
    z = "zoxide query -i";
  };

  # zoxide is initialized via `zoxide init fish <flags> | source` and is
  # therefore not wrapped with flags

  programs.zoxide = {
    enable = true;
    enableBashIntegration = true;
    enableFishIntegration = true;
    flags = [ "--cmd cd" ];
  };

  custom.persist = {
    home = {
      cache.directories = [ ".local/share/zoxide" ];
    };
  };
}
