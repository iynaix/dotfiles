{
  config,
  lib,
  pkgs,
  user,
  ...
}: let
  cfg = config.iynaix-nixos.sops;
in {
  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [age sops];

    # to edit secrets file, run "sops hosts/secrets.json"
    sops.defaultSopsFile = ../hosts/secrets.json;
    sops.age.sshKeyPaths = ["/persist/home/${user}/.ssh/id_ed25519"];
    sops.gnupg.sshKeyPaths = [];
    sops.age.keyFile = "/persist/home/${user}/.config/sops/age/keys.txt";
    # This will generate a new key if the key specified above does not exist
    sops.age.generateKey = false;

    users.users.${user}.extraGroups = [config.users.groups.keys.name];

    iynaix-nixos.persist.home = {
      directories = [
        ".config/sops"
      ];
    };
  };
}
