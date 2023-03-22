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
      home = {
        packages = [pkgs.smplayer];

        file.".config/smplayer/themes" = {
          source = ./smplayer-themes;
          recursive = true;
        };
      };
    };
  };
}
