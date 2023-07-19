{pkgs, ...}: {
  config = {
    services.xserver.enable = true;
    services.gnome.gnome-keyring.enable = true;
    security.polkit.enable = true;

    # enable polkit
    # https://nixos.wiki/wiki/Polkit
    systemd = {
      user.services.polkit-gnome-authentication-agent-1 = {
        description = "polkit-gnome-authentication-agent-1";
        wantedBy = ["graphical-session.target"];
        wants = ["graphical-session.target"];
        after = ["graphical-session.target"];
        serviceConfig = {
          Type = "simple";
          ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
          Restart = "on-failure";
          RestartSec = 1;
          TimeoutStopSec = 10;
        };
      };
    };

    # persist keyring and misc other secrets
    iynaix-nixos.persist.home = {
      directories = [
        ".gnupg"
        ".pki"
        ".ssh"
        ".local/share/keyrings"
      ];
      files = [
        ".ssh/id_rsa"
      ];
    };
  };
}
