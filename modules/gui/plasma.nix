{
  hosts = [ "vm" ]; # 3d acceleration is slow af in a VM, so use plasma instead

  config =
    { lib, pkgs, ... }:
    {
      services = {
        desktopManager.plasma6.enable = true;

        displayManager.defaultSession = lib.mkForce "plasma";
      };

      # set dark theme, adapted from plasma-manager
      environment.etc."xdg/autostart/plasma-dark-mode.desktop".source = pkgs.makeDesktopItem {
        name = "plasma-dark-mode";
        desktopName = "Plasma Dark Mode";
        exec = pkgs.writeShellScript "plasma-dark-mode" ''
          plasma-apply-lookandfeel -a org.kde.breezedark.desktop
          plasma-apply-desktoptheme breeze-dark
        '';
        extraConfig = {
          "X-KDE-autostart-condition" = "ksmserver";
        };
      };
    };
}
