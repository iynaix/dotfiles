{
  config,
  lib,
  user,
  ...
}: let
  autoLoginUser = config.services.xserver.displayManager.autoLogin.user;
  inherit (config.sops) secrets;
in {
  # autologin
  services = {
    xserver.displayManager.autoLogin.user = lib.mkDefault (
      if config.boot.zfs.requestEncryptionCredentials
      then user
      else null
    );
    getty.autologinUser = autoLoginUser;
  };

  # setup users with persistent passwords
  # https://reddit.com/r/NixOS/comments/o1er2p/tmpfs_as_root_but_without_hardcoding_your/h22f1b9/
  # https://github.com/Mic92/sops-nix?tab=readme-ov-file#setting-a-users-password
  sops.secrets = {
    rp.neededForUsers = true;
    up.neededForUsers = true;
  };

  users = {
    mutableUsers = false;
    # create a password with for root and $user with:
    # mkpasswd -m sha-512 'PASSWORD' | sudo tee -a /persist/etc/shadow/root
    users = {
      root.hashedPasswordFile = secrets.rp.path;
      ${user} = {
        isNormalUser = true;
        initialPassword = "password";
        hashedPasswordFile = secrets.up.path;
        extraGroups = ["networkmanager" "wheel"];
      };
    };
  };
}
