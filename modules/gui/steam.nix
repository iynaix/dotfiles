{
  flake.nixosModules.steam =
    { config, pkgs, ... }:
    {
      programs.steam = {
        enable = true;
        # get rid of ~/.steam directory:
        # https://github.com/ValveSoftware/steam-for-linux/issues/1890#issuecomment-2367103614
        package = pkgs.steam.override {
          extraBwrapArgs = [
            "--bind /persist/${config.hj.directory} $HOME"
            "--unsetenv XDG_CACHE_HOME"
            "--unsetenv XDG_CONFIG_HOME"
            "--unsetenv XDG_DATA_HOME"
            "--unsetenv XDG_STATE_HOME"
          ];
        };
      };

      custom.persist = {
        home.directories = [
          ".local/share/applications" # desktop files from steam
          ".local/share/icons/hicolor" # icons from steam
          ".local/share/Steam"
        ];
      };
    };
}
