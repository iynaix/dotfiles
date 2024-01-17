{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.custom.ghostty;
  inherit (config.custom) terminal;
in {
  config = lib.mkIf cfg.enable {
    # open ghostty from nemo
    custom.terminal.fakeGnomeTerminal = lib.mkIf (terminal.package == pkgs.ghostty) (pkgs.writeShellApplication {
      name = "gnome-terminal";
      text = ''
        shift

        TITLE="$(basename "$1")"
        if [ -n "$TITLE" ]; then
          ${terminal.exec} --title "$TITLE" "$@"
        else
          ${terminal.exec} "$@"
        fi
      '';
    });

    home = {
      packages = [pkgs.ghostty];
      sessionVariables = {
        GHOSTTY_RESOURCES_DIR = "${pkgs.ghostty}/share";
      };
    };

    xdg.configFile."ghostty/config".text =
      lib.generators.toKeyValue {
        mkKeyValue = lib.generators.mkKeyValueDefault {} " = ";
        listsAsDuplicateKeys = true;
      } {
        # adjust-cell-height = 1;
        background = "#000000";
        background-opacity = terminal.opacity;
        command =
          if (config.custom.shell.interactive == "fish")
          then "${lib.getExe pkgs.fish}"
          else "${lib.getExe pkgs.bash}";
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

    wayland.windowManager.hyprland.settings.bind = ["$mod, q, exec, ${lib.getExe pkgs.ghostty}"];
  };
}
