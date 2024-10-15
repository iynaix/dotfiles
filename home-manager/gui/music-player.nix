{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
{
  options.custom = with lib; {
    music-player.enable = mkEnableOption "music-player";
  };

  config = lib.mkIf config.custom.music-player.enable {
    home.packages = with pkgs; [
      inputs.music-player.${system}.default
    ];

    custom.persist = {
      home.directories = [ ".config/music-player" ];
    };
  };
}
