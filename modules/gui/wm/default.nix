{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) mkIf;
in
mkIf config.custom.isWm {
  environment = {
    sessionVariables = {
      DISPLAY = ":0";
      NIXOS_OZONE_WL = "1";
      QT_QPA_PLATFORM = "wayland;xcb";
      # GDK_BACKEND = "wayland,x11,*";
    };
  };

  # WM agnostic polkit authentication agent
  systemd.user.services.polkit-gnome = {
    wantedBy = [ "graphical-session.target" ];

    unitConfig = {
      Description = "GNOME PolicyKit Agent";
      After = [ "graphical-session.target" ];
      PartOf = [ "graphical-session.target" ];
    };

    serviceConfig = {
      ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
    };
  };
}
