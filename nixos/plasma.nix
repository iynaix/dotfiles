{
  config,
  lib,
  pkgs,
  ...
}:
lib.mkIf config.custom.plasma.enable {
  services = {
    xserver.enable = true;
    xserver.desktopManager.plasma5.enable = true;
  };

  hm = {
    custom.hyprland.enable = lib.mkForce false;

    # set dark theme, adapted from plasma-manager
    xdg.configFile."autostart/plasma-dark-mode.desktop".text =
      let
        plasmaDarkMode = pkgs.writeShellScriptBin "plasma-dark-mode" ''
          plasma-apply-lookandfeel -a org.kde.breezedark.desktop
          plasma-apply-desktoptheme breeze-dark
        '';
      in
      ''
        [Desktop Entry]
        Type=Application
        Name=Plasma Dark Mode
        Exec=${lib.getExe plasmaDarkMode}
        X-KDE-autostart-condition=ksmserver
      '';
  };
}
