{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkEnableOption mkIf;
in
{
  options.custom = {
    programs.vlc.enable = mkEnableOption "vlc";
  };

  config = mkIf config.custom.programs.vlc.enable {
    environment.systemPackages = [ pkgs.vlc ];

    custom.persist = {
      home.directories = [ ".config/vlc" ];
    };
  };
}
