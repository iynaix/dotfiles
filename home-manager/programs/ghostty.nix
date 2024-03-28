{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.custom.ghostty;
  ghostty = inputs.ghostty.packages.${pkgs.system}.default;
  inherit (config.custom) terminal;
in
lib.mkIf cfg.enable {
  home = {
    packages = [ ];
    sessionVariables = {
      GHOSTTY_RESOURCES_DIR = "${ghostty}/share";
    };
  };

  xdg.configFile."ghostty/config".text = lib.generators.toKeyValue {
    mkKeyValue = lib.generators.mkKeyValueDefault { } " = ";
    listsAsDuplicateKeys = true;
  } config.custom.ghostty.config;

  custom.ghostty.config = {
    # adjust-cell-height = 1;
    background = "#000000";
    background-opacity = terminal.opacity;
    confirm-close-surface = false;
    copy-on-select = true;
    cursor-style = "bar";
    font-family = terminal.font;
    font-feature = "zero";
    font-size = terminal.size;
    font-style = "Medium";
    minimum-contrast = 1.1;
    # term = "xterm-kitty";
    # theme = "catppuccin-mocha";
    window-decoration = false;
    window-padding-x = terminal.padding;
    window-padding-y = terminal.padding;
  };

  wayland.windowManager.hyprland.settings.bind = [ "$mod, q, exec, ${lib.getExe ghostty}" ];
}
