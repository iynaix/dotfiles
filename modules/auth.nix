{ lib, ... }:
{
  flake.modules.nixos.core =
    { config, ... }:
    let
      inherit (config.custom.constants) user;
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
              directories = [
                "/etc/ssh"
              ];
            };
            home = {
              directories = [
                # ".pki" # chromium recreates this directory, so it can't be moved to $XDG_DATA_HOME/.pki
                ".ssh"
                ".local/share/.gnupg"
                ".local/share/keyrings"
              ];
            };
          };
        }

        {
          services.displayManager = {
            autoLogin.user = user;

            # scrolling is nicer for laptop with a smaller screen
            defaultSession = lib.mkDefault "niri";

            ly = {
              enable = true;
              settings = {
                bigclock = "en";
                save = false; # don't use previous successful session
                session_log = "${config.hj.xdg.data.directory}/ly-session.log";
              };
            };
          };

          custom.programs.print-config = {
            ly = /* sh */ ''moor "/etc/ly/config.ini"'';
          };

          # block other ttys from autologin when bypassed from lockscreen
          services.getty.autologinUser = lib.mkIf (!config.custom.lock.enable) user;
        }
      ];
    };

}
