{
  pkgs,
  lib,
  config,
  ...
}: {
  config = lib.mkIf config.iynaix-nixos.torrenters.enable {
    hm = {
      home.packages = [pkgs.filezilla];
    };

    iynaix-nixos.persist.home.directories = [
      ".config/filezilla"
    ];
  };
}
