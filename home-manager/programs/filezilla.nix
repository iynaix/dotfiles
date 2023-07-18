{
  pkgs,
  lib,
  config,
  ...
}: {
  config = lib.mkIf config.iynaix.torrenters.enable {
    home.packages = with pkgs; [
      filezilla
    ];

    iynaix.persist.home.directories = [
      ".config/filezilla"
    ];
  };
}
