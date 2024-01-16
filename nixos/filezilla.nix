{
  pkgs,
  lib,
  config,
  ...
}: {
  config = lib.mkIf config.custom-nixos.bittorrent.enable {
    hm = {
      home.packages = [pkgs.filezilla];

      custom.persist.home.directories = [
        ".config/filezilla"
      ];
    };
  };
}
