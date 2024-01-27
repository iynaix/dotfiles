{
  config,
  lib,
  pkgs,
  user,
  ...
}: let
  homeDir = config.hm.home.homeDirectory;
in
  lib.mkIf config.custom-nixos.sops.enable {
    # sops is always enabled because github token
    environment.systemPackages = with pkgs; [age sops];

    sops = {
      # to edit secrets file, run "sops hosts/secrets.json"
      defaultSopsFile = ../hosts/secrets.json;

      # use full path to persist as the secrets activation script runs at the start
      # of stage 2 boot before impermanence
      gnupg.sshKeyPaths = [];
      age = {
        sshKeyPaths = ["/persist${homeDir}/.ssh/id_ed25519"];
        keyFile = "/persist${homeDir}/.config/sops/age/keys.txt";
        # This will generate a new key if the key specified above does not exist
        generateKey = false;
      };
    };

    users.users.${user}.extraGroups = [config.users.groups.keys.name];

    custom-nixos.persist.home = {
      directories = [
        ".config/sops"
      ];
    };
  }
