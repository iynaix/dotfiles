{
  pkgs,
  user,
  config,
  lib,
  ...
}: let
  # create a fake gnome-terminal shell script so xdg terminal applications
  # will open in kitty
  # https://unix.stackexchange.com/a/642886
  fakeGnomeTerminal = pkgs.writeShellScriptBin "gnome-terminal" ''
    shift

    TITLE="$(basename "$1")"
    if [ -n "$TITLE" ]; then
      ${pkgs.kitty}/bin/kitty -T "$TITLE" -e "$@"
    else
      ${pkgs.kitty}/bin/kitty "$@"
    fi
  '';
in {
  environment.systemPackages = [fakeGnomeTerminal];

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
          tab_bar_edge = "top";
          background_opacity = toString opacity;
          confirm_os_window_close = 0;
          font_features = "JetBrainsMonoNerdFontComplete-Regular +zero";
        };
      };
    };
  };
}
