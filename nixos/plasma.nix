{
  config,
  lib,
  pkgs,
  ...
}:
{
  options.custom = with lib; {
    plasma.enable = mkEnableOption "Plasma Desktop";
  };

  config = lib.mkIf config.custom.plasma.enable {
    services = {
      xserver.enable = true;
      xserver.desktopManager.plasma5.enable = true;
    };

    hm = {
      custom.hyprland.enable = lib.mkForce false;

      home.packages = with pkgs; [
        # plasma5 currently still uses x11
        xclip
      ];

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
    };
  };
}
