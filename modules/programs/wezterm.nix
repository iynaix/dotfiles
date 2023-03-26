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
      ${pkgs.wezterm}/bin/wezterm start --always-new-process --class "$TITLE" "$@"
    else
      ${pkgs.wezterm}/bin/wezterm start --always-new-process "$@"
    fi
  '';
in {
  # environment.systemPackages = [fakeGnomeTerminal];

  home-manager.users.${user} = {
    home.packages = [pkgs.lsix];

    home.file.".config/wal/templates/colors.toml".text = ''
      [colors]
      ansi = [
        '{color0}',
        '{color1}',
        '{color2}',
        '{color3}',
        '{color4}',
        '{color5}',
        '{color6}',
        '{color7}',
      ]
      background = '{background}'
      brights = [
        '{color8}',
        '{color9}',
        '{color10}',
        '{color11}',
        '{color12}',
        '{color13}',
        '{color14}',
        '{color15}',
      ]
      cursor_bg = '{background}'
      cursor_border = '{cursor}'
      cursor_fg = '{cursor}'
      foreground = '{foreground}'
      selection_bg = '{foreground}'
      selection_fg = '{background}'

      [colors.indexed]

      [metadata]
      name = 'Pywal'
      origin_url = 'https://github.com/dylanaraps/pywal'
    '';

    programs = {
      wezterm = {
        enable = true;
        extraConfig = with config.iynaix.terminal; ''
          local wezterm = require "wezterm"

          return {
            front_end = "WebGpu",
            font = wezterm.font('${font}', {
              weight = "Regular",
            }),
            harfbuzz_features = { 'zero=1' },
            font_size = ${toString (size - 1)},
            window_background_opacity = ${toString opacity},
            enable_scroll_bar = false,
            enable_tab_bar = false,
            enable_wayland = false,
            scrollback_lines = 10000,
            color_scheme_dirs = { "/home/${user}/.cache/wal" },
            color_scheme = "Pywal",
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

  nixpkgs.overlays = [
    (self: super: {
      lsix = super.lsix.overrideAttrs (old: {
        # add default font to silence null font errors
        postFixup = ''
          substituteInPlace $out/bin/lsix \
            --replace '#fontfamily=Mincho' 'fontfamily="JetBrains-Mono-Regular-Nerd-Font-Complete"'
          ${old.postFixup}
        '';
      });
    })
  ];
}
