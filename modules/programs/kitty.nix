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
  fakeGnomeTerminal =
    pkgs.writeShellScriptBin "gnome-terminal"
    /*
    sh
    */
    ''
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

  # do not install xterm
  services.xserver.excludePackages = [pkgs.xterm];

  home-manager.users.${user} = {
    programs = {
      kitty = {
        enable = true;
        theme = "Catppuccin-Mocha";
        font = {
          name = config.iynaix.font.monospace;
          size = lib.mkDefault 11;
        };
        settings = {
          enable_audio_bell = false;
          copy_on_select = "clipboard";
          scrollback_lines = 10000;
          update_check_interval = 0;
          window_margin_width = 12;
          tab_bar_edge = "top";
          background_opacity = "0.6";
          confirm_os_window_close = 0;
          font_features = "JetBrainsMonoNerdFontComplete-Regular +zero";
        };
      };
    };
  };
}
