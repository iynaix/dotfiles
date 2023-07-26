{
  pkgs,
  user,
  config,
  ...
}: {
  config = {
    environment.systemPackages = with pkgs; [age sops];

    # to edit secrets file, run "sops hosts/secrets.yaml"
    sops.defaultSopsFile = ../hosts/secrets.yaml;
    sops.age.sshKeyPaths = ["/home/${user}/.ssh/id_ed25519"];
    # This is using an age key that is expected to already be in the filesystem
    sops.age.keyFile = "/home/${user}/.config/sops/age/keys.txt";
    # This will generate a new key if the key specified above does not exist
    sops.age.generateKey = false;

    # This is the actual specification of the secrets.
    sops.secrets = {
      sonarr_api_key.owner = user;
      netlify_site_id.owner = user;
    };

    users.users.${user}.extraGroups = [config.users.groups.keys.name];

    systemd.services.some-service = {
      serviceConfig.SupplementaryGroups = [config.users.groups.keys.name];
    };

    # persist keyring and misc other secrets
    iynaix-nixos.persist.home = {
      directories = [
        ".config/sops"
      ];
    };
  };
}
