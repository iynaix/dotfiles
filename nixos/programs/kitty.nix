{
  user,
  config,
  lib,
  pkgs,
  ...
}: {
  options.iynaix.kitty = {
    enable = lib.mkEnableOption "kitty" // {default = true;};
  };

  config = lib.mkIf config.iynaix.kitty.enable {
    iynaix.terminal.fakeGnomeTerminal = lib.mkIf (config.iynaix.terminal.package == pkgs.kitty) (pkgs.writeShellScriptBin "gnome-terminal" ''
      shift

      TITLE="$(basename "$1")"
      if [ -n "$TITLE" ]; then
        ${config.iynaix.terminal.exec} -T "$TITLE" "$@"
      else
        ${config.iynaix.terminal.exec} "$@"
      fi
    '');

    home-manager.users.${user} = {
      programs = {
        kitty = with config.iynaix.terminal; {
          enable = true;
          theme = "Catppuccin-Mocha";
          font = {
            name = font;
            size = size;
          };
          settings = {
            enable_audio_bell = false;
            copy_on_select = "clipboard";
            scrollback_lines = 10000;
            update_check_interval = 0;
            window_margin_width = padding;
            single_window_margin_width = padding;
            tab_bar_edge = "top";
            background_opacity = toString opacity;
            confirm_os_window_close = 0;
            font_features = "JetBrainsMonoNerdFontComplete-Regular +zero";
          };
        };
      };
    };
  };
}
