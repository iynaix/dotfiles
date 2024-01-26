{
  config,
  lib,
  pkgs,
  ...
}:
lib.mkIf config.custom.vlc.enable {
  home.packages = [pkgs.vlc];

  custom.persist = {
    home.directories = [
      ".config/vlc"
    ];
  };
}
