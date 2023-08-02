{user, ...}: let
  sshKeyFile1 = ../home-manager/id_rsa.pub;
  sshKeyFile2 = ../home-manager/id_ed25519.pub;
in {
  config = {
    services.openssh = {
      enable = true;
      authorizedKeysFiles = [
        "${sshKeyFile1}"
        "${sshKeyFile2}"
      ];
      settings.PasswordAuthentication = false;
    };

    users.users.${user}.openssh.authorizedKeys.keys = [
      (builtins.readFile sshKeyFile1)
      (builtins.readFile sshKeyFile2)
    ];

    services.gnome.gnome-keyring.enable = true;
    security.polkit.enable = true;

    # Some programs need SUID wrappers, can be configured further or are
    # started in user sessions.
    programs.gnupg.agent = {
      enable = true;
      enableSSHSupport = true;
    };

    # setup autologin
    # NOTE: for autologin, the keyring needs to be setup with a blank password so it can be unlocked on boot
    services.getty.autologinUser = user;
    services.xserver = {
      enable = true;

      displayManager.autoLogin = {
        enable = true;
        inherit user;
      };
    };

    # shut sudo up
    security.sudo.extraConfig = "Defaults lecture=never";

    # persist keyring and misc other secrets
    iynaix-nixos.persist.home = {
      directories = [
        ".gnupg"
        ".pki"
        ".ssh"
        ".local/share/keyrings"
      ];
    };
  };
}
