{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
in
mkIf (config.custom.wm == "plasma") {
  # set dark theme, adapted from plasma-manager
  xdg.configFile."autostart/plasma-dark-mode.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Plasma Dark Mode
    Exec=${pkgs.writeShellScript "plasma-dark-mode" ''
      plasma-apply-lookandfeel -a org.kde.breezedark.desktop
      plasma-apply-desktoptheme breeze-dark
    ''}
    X-KDE-autostart-condition=ksmserver
  '';
}
