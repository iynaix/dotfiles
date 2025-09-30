{
  config,
  pkgs,
  user,
  ...
}:
{
  sops = {
    # to edit secrets file, run "sops hosts/secrets.json"
    defaultSopsFile = ../hosts/secrets.json;

    # use full path to persist as the secrets activation script runs at the start
    # of stage 2 boot before impermanence
    gnupg.sshKeyPaths = [ ];
    age = {
      sshKeyPaths = [ "/persist${config.hj.directory}/.ssh/id_ed25519" ];
      keyFile = "/persist${config.hj.directory}/.config/sops/age/keys.txt";
      # This will generate a new key if the key specified above does not exist
      generateKey = false;
    };
  };

  users.users.${user}.extraGroups = [ config.users.groups.keys.name ];

  # script to bootstrap a new install
  custom.shell.packages = {
    install-remote-secrets = {
      runtimeInputs = [ pkgs.rsync ];
      text =
        let
          persistHome = "/persist${config.hj.directory}";
          copy = src: ''rsync -aP --mkpath "${persistHome}/${src}" "$user@$remote:$target/${src}"'';
        in
        # sh
        ''
          read -rp "Enter ip of remote host: " remote
          target="/mnt${persistHome}"

          while true; do
              read -rp "Use /mnt? [y/n] " yn
              case $yn in
                [Yy]*)
                  echo "y";
                  target="/mnt${persistHome}"
                  break;;
                [Nn]*)
                  echo "n";
                  target="${persistHome}"
                  break;;
                *)
                  echo "Please answer yes or no.";;
              esac
          done

          read -rp "Enter user on remote host: [nixos] " user
          user=''${user:-nixos}

          ${copy ".ssh/"}
          ${copy ".config/sops/age/"}
        '';
    };
  };

  custom.persist.home = {
    directories = [ ".config/sops" ];
  };
}
