{
  pkgs,
  user,
  ...
}: {
  config = {
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
