{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.custom.kitty;
  inherit (config.custom) terminal;
in
  lib.mkIf cfg.enable {
    # open kitty from nemo
    custom.terminal.fakeGnomeTerminal = lib.mkIf (terminal.package == pkgs.kitty) (pkgs.writeShellApplication {
      name = "gnome-terminal";
      text = ''
        shift

        TITLE="$(basename "$1")"
        if [ -n "$TITLE" ]; then
          ${terminal.exec} -T "$TITLE" "$@"
        else
          ${terminal.exec} "$@"
        fi
      '';
    });

    programs.kitty = {
      enable = true;
      theme = "Catppuccin-Mocha";
      font = {
        name = terminal.font;
        inherit (terminal) size;
      };
      settings = {
        enable_audio_bell = false;
        copy_on_select = "clipboard";
        scrollback_lines = 10000;
        update_check_interval = 0;
        window_margin_width = terminal.padding;
        single_window_margin_width = terminal.padding;
        tab_bar_edge = "top";
        background_opacity = terminal.opacity;
        confirm_os_window_close = 0;
        font_features = "+zero";
        shell =
          if (config.custom.shell.interactive == "fish")
          then "${lib.getExe pkgs.fish}"
          else ".";
      };
    };

    home.shellAliases = {
      # change color on ssh
      ssh = "kitten ssh --kitten=color_scheme=Dracula";
    };
  }
