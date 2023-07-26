{
  pkgs,
  user,
  lib,
  ...
}: {
  config = {
    environment.systemPackages = with pkgs; [age sops];

    sops.defaultSopsFile = ../hosts/secrets.yaml;
    sops.age.sshKeyPaths = ["/home/${user}/.ssh/id_ed25519"];
    # This is using an age key that is expected to already be in the filesystem
    sops.age.keyFile = "/home/${user}/.config/sops/age/keys.txt";
    # This will generate a new key if the key specified above does not exist
    sops.age.generateKey = false;

    # This is the actual specification of the secrets.
    sops.secrets.sonarr_api_key = {};
    sops.secrets.netlify_site_id = {};

    users.users.${user}.extraGroups = lib.mkAfter ["keys"];

    # persist keyring and misc other secrets
    iynaix-nixos.persist.home = {
      directories = [
        ".config/sops"
      ];
    };
  };
}
