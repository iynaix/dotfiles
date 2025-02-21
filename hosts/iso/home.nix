{
  isoPath,
  lib,
  pkgs,
  user,
  ...
}:
let
  inherit (lib) mkIf;
in
{
  home = {
    username = user;
    homeDirectory = "/home/${user}";
    stateVersion = "24.05";
  };

  # set dark theme for kde, adapted from plasma-manager
  xdg.configFile = {
    "autostart/plasma-dark-mode.desktop" = mkIf (lib.hasInfix "plasma" isoPath) {
      text = ''
        [Desktop Entry]
        Type=Application
        Name=Plasma Dark Mode
        Exec=${pkgs.writeShellScript "plasma-dark-mode" ''
          plasma-apply-lookandfeel -a org.kde.breezedark.desktop
          plasma-apply-desktoptheme breeze-dark
        ''}
        X-KDE-autostart-condition=ksmserver
      '';
    };
  };

  # better defaults for yazi
  programs.yazi = {
    enable = true;
    enableBashIntegration = true;
    enableFishIntegration = true;

    settings = {
      manager = {
        ratio = [
          0
          1
          1
        ];
        sort_by = "alphabetical";
        sort_sensitive = false;
        sort_reverse = false;
        linemode = "size";
        show_hidden = true;
      };
    };

    theme = {
      manager = {
        preview_hovered = {
          underline = false;
        };
        folder_offset = [
          1
          0
          1
          0
        ];
        preview_offset = [
          1
          1
          1
          1
        ];
      };
    };
  };
}
