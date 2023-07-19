{
  pkgs,
  lib,
  config,
  user,
  ...
}: {
  config = lib.mkIf config.iynaix-nixos.torrenters.enable {
    home-manager.users.${user} = {
      home.packages = with pkgs; [
        filezilla
      ];
    };

    iynaix-nixos.persist.home.directories = [
      ".config/filezilla"
    ];
  };
}
