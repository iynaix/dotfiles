{
  config,
  lib,
  user,
  ...
}:
let
  inherit (lib)
    filter
    hasInfix
    mkForce
    mkMerge
    mkOption
    ;
in
{
  # silence warning about setting multiple user password options
  # https://github.com/NixOS/nixpkgs/pull/287506#issuecomment-1950958990
  options = {
    warnings = mkOption {
      apply = filter (w: !(hasInfix "If multiple of these password options are set at the same time" w));
    };
  };

  config = mkMerge [
    {
      users = {
        mutableUsers = false;
        # setup users with persistent passwords
        # https://reddit.com/r/NixOS/comments/o1er2p/tmpfs_as_root_but_without_hardcoding_your/h22f1b9/
        # create a password with for root and $user with:
        # read -s -p "" PASSWORD && mkpasswd -m sha-512 "$PASSWORD" | sudo tee -a /persist/etc/shadow/root
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
    {
      # https://github.com/Mic92/sops-nix?tab=readme-ov-file#setting-a-users-password
      sops.secrets = {
        rp.neededForUsers = true;
        up.neededForUsers = true;
      };

      # create a password with for root and $user with:
      # mkpasswd -m sha-512 'PASSWORD' and place in secrets.json under the appropriate key
      users.users = {
        root.hashedPasswordFile = mkForce config.sops.secrets.rp.path;
        ${user}.hashedPasswordFile = mkForce config.sops.secrets.up.path;
      };
    }
  ];
}
