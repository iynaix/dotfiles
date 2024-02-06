{
  config,
  lib,
  user,
  ...
}:
let
  autoLoginUser = config.services.xserver.displayManager.autoLogin.user;
in
lib.mkMerge [
  {
    # autologin
    services = {
      xserver.displayManager.autoLogin.user = lib.mkDefault (
        if config.boot.zfs.requestEncryptionCredentials then user else null
      );
      getty.autologinUser = autoLoginUser;
    };

    users = {
      mutableUsers = false;
      # setup users with persistent passwords
      # https://reddit.com/r/NixOS/comments/o1er2p/tmpfs_as_root_but_without_hardcoding_your/h22f1b9/
      # create a password with for root and $user with:
      # mkpasswd -m sha-512 'PASSWORD' | sudo tee -a /persist/etc/shadow/root
      users = {
        root = {
          initialPassword = "password";
          hashedPasswordFile = "/persist/etc/shadow/root";
        };
        ${user} = {
          isNormalUser = true;
          initialPassword = "password";
          hashedPasswordFile = "/persist/etc/shadow/${user}";
          extraGroups = [
            "networkmanager"
            "wheel"
          ];
        };
      };
    };
  }

  # use sops for user passwords if enabled
  (lib.mkIf config.custom-nixos.sops.enable (
    let
      inherit (config.sops) secrets;
    in
    {
      # https://github.com/Mic92/sops-nix?tab=readme-ov-file#setting-a-users-password
      sops.secrets = {
        rp.neededForUsers = true;
        up.neededForUsers = true;
      };

      users = {
        mutableUsers = false;
        # create a password with for root and $user with:
        # mkpasswd -m sha-512 'PASSWORD' and place in secrets.json under the appropriate key
        users = {
          root.hashedPasswordFile = lib.mkForce secrets.rp.path;
          ${user}.hashedPasswordFile = lib.mkForce secrets.up.path;
        };
      };
    }
  ))
]
