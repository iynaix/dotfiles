{
  config,
  lib,
  pkgs,
  user,
  ...
}: let
  autoLoginUser = config.services.xserver.displayManager.autoLogin.user;
in {
  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
    settings.KbdInteractiveAuthentication = false;
  };

  users.users = let
    keyFiles = [
      ../home-manager/id_rsa.pub
      ../home-manager/id_ed25519.pub
    ];
  in {
    root.openssh.authorizedKeys.keyFiles = keyFiles;
    ${user}.openssh.authorizedKeys.keyFiles = keyFiles;
  };

  services.gnome.gnome-keyring.enable = true;
  security.polkit.enable = true;

  environment.systemPackages = [pkgs.gcr]; # stops errors with copilot login?

  # configure autologin if enabled
  services.xserver.displayManager.autoLogin.user = lib.mkDefault (
    if config.boot.zfs.requestEncryptionCredentials
    then user
    else null
  );
  services.getty.autologinUser = autoLoginUser;
  security.pam.services.gdm.enableGnomeKeyring = autoLoginUser != null;

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  programs.gnupg.agent = {
    enable = true;
    enableSSHSupport = true;
  };

  # i can't type
  security.sudo.extraConfig = "Defaults passwd_tries=10";

  # persist keyring and misc other secrets
  iynaix-nixos.persist.home = {
    directories = [
      ".gnupg"
      ".pki"
      ".ssh"
      ".local/share/keyrings"
    ];
  };
}
