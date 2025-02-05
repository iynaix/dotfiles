{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.custom.ghostty;
  inherit (config.custom) terminal;
in
{
  options.custom = with lib; {
    ghostty = {
      enable = mkEnableOption "ghostty" // {
        default = true;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    programs.ghostty = {
      enable = true;
      enableBashIntegration = true;
      enableFishIntegration = true;
      settings = {
        background-opacity = terminal.opacity;
        confirm-close-surface = false;
        copy-on-select = true;
        cursor-style = "bar";
        font-family = terminal.font;
        font-feature = "zero";
        font-size = terminal.size;
        font-style = "Medium";
        minimum-contrast = 1.1;
        window-decoration = false;
        window-padding-x = terminal.padding;
        window-padding-y = terminal.padding;
      };
    };

    wayland.windowManager.hyprland.settings.bind = [ "$mod, q, exec, ${lib.getExe pkgs.ghostty}" ];
  };
}
