{ config, lib, ... }:
{
  options.custom = with lib; {
    helix = {
      enable = mkEnableOption "helix" // {
        default = true;
      };
    };
  };

  config = lib.mkIf config.custom.helix.enable {
    programs.helix = {
      enable = true;
      settings = {
        theme = "catppuccin_mocha";
      };
    };
  };
}
