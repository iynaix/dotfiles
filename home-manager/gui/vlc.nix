{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.custom = with lib; {
    vlc.enable = mkEnableOption "vlc";
  };

  config = lib.mkIf config.custom.vlc.enable {
    home.packages = [ pkgs.vlc ];

    custom.persist = {
      home.directories = [ ".config/vlc" ];
    };
  };
}
