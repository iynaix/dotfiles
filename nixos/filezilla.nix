{
  config,
  lib,
  pkgs,
  ...
}:
lib.mkIf config.custom.bittorrent.enable {
  hm = {
    home.packages = [ pkgs.filezilla ];

    custom.persist.home.directories = [ ".config/filezilla" ];
  };
}
