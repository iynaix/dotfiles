{
  pkgs,
  user,
  config,
  lib,
  ...
}: {
  options = {
    iynaix.smplayer = {
      enable = lib.mkEnableOption "smplayer";
    };
  };

  config = {
    home-manager.users.${user} = {
      xdg.configFile."smplayer/themes" = {
        source = ./smplayer-themes;
        recursive = true;
      };

      home.packages = [pkgs.smplayer];
    };
  };
}
