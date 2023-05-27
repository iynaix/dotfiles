{
  pkgs,
  user,
  lib,
  config,
  ...
}: {
  config = lib.mkIf config.iynaix.torrenters.enable {
    home-manager.users.${user} = {
      home = {
        packages = with pkgs; [
          filezilla
        ];
      };
    };

    iynaix.persist.home.directories = [
      ".config/filezilla"
    ];
  };
}
