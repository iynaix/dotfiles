{
  pkgs,
  user,
  config,
  lib,
  ...
}: let
  cfg = config.iynaix-nixos.sops;
in {
  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [age sops];

    # to edit secrets file, run "sops hosts/secrets.json"
    sops.defaultSopsFile = ../hosts/secrets.json;
    sops.age.sshKeyPaths = ["/home/${user}/.ssh/id_ed25519"];
    # This is using an age key that is expected to already be in the filesystem
    sops.age.keyFile = "/home/${user}/.config/sops/age/keys.txt";
    # This will generate a new key if the key specified above does not exist
    sops.age.generateKey = false;

    users.users.${user}.extraGroups = [config.users.groups.keys.name];

    systemd.services.some-service = {
      serviceConfig.SupplementaryGroups = [config.users.groups.keys.name];
    };

    iynaix-nixos.persist.home = {
      directories = [
        ".config/sops"
      ];
    };
  };
}
