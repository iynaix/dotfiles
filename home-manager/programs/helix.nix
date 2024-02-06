{ config, lib, ... }:
lib.mkIf config.custom.helix.enable {
  programs.helix = {
    enable = true;
    settings = {
      theme = "catppuccin_mocha";
    };
  };
}
