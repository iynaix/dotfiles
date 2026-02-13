{ lib, ... }:
{
  flake.nixosModules.core =
    { config, ... }:
    let
      inherit (config.custom.constants) isLaptop user;
    in
    {
      config = lib.mkMerge [
        # ssh settings
        {
          services.openssh = {
            enable = true;
            # disable password auth
            settings = {
              PasswordAuthentication = false;
              KbdInteractiveAuthentication = false;
            };
          };

          users.users =
            let
              keyFiles = [
                ./id_rsa.pub
                ./id_ed25519.pub
              ];
            in
            {
              root.openssh.authorizedKeys.keyFiles = keyFiles;
              ${user}.openssh.authorizedKeys.keyFiles = keyFiles;
            };
        }

        # keyring settings
        {
          services.gnome.gnome-keyring.enable = true;
          security.pam.services.login.enableGnomeKeyring = true;
        }

        {
          security = {
            polkit.enable = true;

            # i can't type
            sudo.extraConfig = "Defaults passwd_tries=10";
          };

          # Some programs need SUID wrappers, can be configured further or are
          # started in user sessions.
          environment.variables = {
            GNUPGHOME = "${config.hj.xdg.data.directory}/.gnupg";
          };

          programs.gnupg.agent = {
            enable = true;
            enableSSHSupport = true;
          };

          # persist keyring and misc other secrets
          custom.persist = {
            root = {
              files = [
                "/etc/ssh/ssh_host_rsa_key"
                "/etc/ssh/ssh_host_rsa_key.pub"
                "/etc/ssh/ssh_host_ed25519_key"
                "/etc/ssh/ssh_host_ed25519_key.pub"
              ];
            };
            home = {
              directories = [
                ".pki"
                ".ssh"
                ".local/share/.gnupg"
                ".local/share/keyrings"
              ];
            };
          };
        }

        {
          services.displayManager = {
            # scrolling is nicer for laptop with a smaller screen
            defaultSession = lib.mkDefault (if isLaptop then "niri" else "hyprland");

            ly = {
              enable = true;
              settings = {
                bigclock = "en";
              };
            };
          };

          # block other ttys from autologin when bypassed from lockscreen
          services.getty.autologinUser = lib.mkIf (!config.custom.lock.enable) user;
        }
      ];
    };

}
