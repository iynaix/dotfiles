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

    ${pkgs.wezterm}/bin/wezterm start "$@"
  '';
in {
  # environment.systemPackages = [fakeGnomeTerminal];

  home-manager.users.${user} = {
    home.packages = [pkgs.lsix];

    programs = {
      wezterm = {
        enable = true;
        extraConfig = with config.iynaix.terminal; ''
          local wezterm = require "wezterm"

          return {
            font = wezterm.font_with_fallback({ "${font}", }, {
              weight = "Regular",
            }),
            font_size = ${toString size},
            color_scheme = "Catppuccin Mocha",
            window_background_opacity = ${toString opacity},
            enable_scroll_bar = false,
            enable_tab_bar = false,
            scrollback_lines = 10000,
            window_padding = {
              left = ${toString padding},
              right = ${toString padding},
              top = ${toString padding},
              bottom = ${toString padding},
            },
            check_for_updates = false,
            default_cursor_style = "SteadyBar",
          }
        '';
      };
    };
  };
}
