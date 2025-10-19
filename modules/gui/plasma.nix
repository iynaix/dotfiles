{
  flake.nixosModules.plasma =
    { pkgs, ... }:
    {
      services = {
        xserver.enable = true;
        xserver.desktopManager.plasma6.enable = true;
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
