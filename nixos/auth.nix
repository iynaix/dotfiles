{
  config,
  lib,
  user,
  ...
}:
let
  inherit (lib) mkMerge optionalAttrs;
in
mkMerge [
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
          ../home-manager/id_rsa.pub
          ../home-manager/id_ed25519.pub
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

  # misc
  {
    security = {
      polkit.enable = true;
      # i can't type
      sudo.extraConfig = "Defaults passwd_tries=10";
    } // optionalAttrs config.hm.programs.hyprlock.enable { pam.services.hyprlock = { }; };

    # Some programs need SUID wrappers, can be configured further or are
    # started in user sessions.
    environment.variables = {
      GNUPGHOME = "${config.hm.xdg.dataHome}/.gnupg";
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
]
