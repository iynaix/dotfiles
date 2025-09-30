{
  config,
  lib,
  user,
  ...
}:
let
  inherit (lib)
    mkMerge
    mkOption
    optionalAttrs
    types
    ;
  inherit (types) nullOr str;
in
{
  options.custom = {
    autologinCommand = mkOption {
      type = nullOr str;
      default = null;
      description = "Command to run after autologin";
    };
  };

  config = mkMerge [
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

    # autologin
    {
      services = {
        greetd =
          let
            inherit (config.custom) autologinCommand;
          in
          {
            enable = autologinCommand != null;

            settings = {
              default_session = {
                command = autologinCommand;
              };

              initial_session = {
                inherit user;
                command = autologinCommand;
              };
            };
          };

        getty.autologinUser = config.services.displayManager.autoLogin.user;
      };
    }

    # misc
    {
      security = {
        polkit.enable = true;

        # i can't type
        sudo.extraConfig = "Defaults passwd_tries=10";
      }
      // optionalAttrs config.custom.lock.enable { pam.services.hyprlock = { }; };

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
  ];
}
