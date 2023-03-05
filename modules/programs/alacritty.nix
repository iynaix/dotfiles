{ pkgs, theme, user, config, lib, ... }:
let
  # create a fake gnome-terminal shell script so xdg terminal applications
  # will open in alacritty
  # https://unix.stackexchange.com/a/642886
  fakeGnomeTerminal = pkgs.writeShellScriptBin "gnome-terminal" /* sh */ ''
    shift

    TITLE="$(basename "$1")"
    if [ -n "$TITLE" ]; then
      ${pkgs.alacritty}/bin/alacritty -t "$TITLE" -e "$@"
    else
      ${pkgs.alacritty}/bin/alacritty -e "$@"
    fi
  '';
in
{
  environment.systemPackages = [ fakeGnomeTerminal ];

  # do not install xterm
  services.xserver.excludePackages = [ pkgs.xterm ];

  home-manager.users.${user} = {
    programs = {
      alacritty = {
        enable = true;
        settings = {
          window.padding = {
            x = 12;
            y = 12;
          };
          font = {
            normal = {
              family = config.iynaix.font.monospace;
              style = "Medium";
            };
            bold = { style = "Bold"; };
            italic = { style = "Italic"; };
            bold_italic = { style = "Bold Italic"; };
            size = lib.mkDefault 11;
          };
          selection.save_to_clipboard = true;
          # window.opacity = 0.5;
          colors = with config.iynaix.xrdb; {
            primary = {
              inherit background foreground;
            };
            normal = {
              black = color0;
              red = color1;
              green = color2;
              yellow = color3;
              blue = color4;
              magenta = color5;
              cyan = color6;
              white = color7;
            };
            bright = {
              black = color8;
              red = color9;
              green = color10;
              yellow = color11;
              blue = color12;
              magenta = color13;
              cyan = color14;
              white = color15;
            };
          };
        };
      };
    };
  };
}
