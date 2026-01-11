{ lib, ... }:
let
  inherit (lib) mkDefault mkIf mkMerge;
in
{
  flake.nixosModules.core =
    {
      config,
      pkgs,
      user,
      ...
    }:
    {
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

        # WM agnostic polkit authentication agent
        {
          systemd.user.services.polkit-gnome = {
            wantedBy = [ "graphical-session.target" ];

            unitConfig = {
              Description = "GNOME PolicyKit Agent";
              After = [ "graphical-session.target" ];
              PartOf = [ "graphical-session.target" ];
            };

            serviceConfig = {
              ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
            };
          };
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
          services.displayManager.ly = {
            enable = true;
            # fix hyprland-uwsm being selected over hyprland, even with auto_login_session = hyprland
            # https://codeberg.org/fairyglade/ly/issues/895
            package = pkgs.ly.overrideAttrs (_o: rec {
              version = "1.3.1";

              src = pkgs.fetchFromGitea {
                domain = "codeberg.org";
                owner = "fairyglade";
                repo = "ly";
                tag = "v${version}";
                hash = "sha256-BelsR/+sfm3qdEnyf4bbadyzuUVvVPrPEhdZaNPLxiE=";
              };
            });
            settings = {
              bigclock = "en";
            }
            // {
              auto_login_service = "ly-autologin";
              # auto_login_session = config.services.displayManager.sessionData.autologinSession;
              auto_login_session = mkDefault "hyprland";
              auto_login_user = user;
            };
          };

          # block other ttys from autologin when bypassed from lockscreen
          services.getty.autologinUser = mkIf (!config.custom.lock.enable) user;

          # copied from ly repo, using absolute path to pam_systemd.so or it would error
          security.pam.services.ly-autologin = {
            text = ''
              auth       required     pam_permit.so
              -auth      optional     pam_gnome_keyring.so
              -auth      optional     pam_kwallet5.so

              account    include      login

              password   include      login
              -password  optional     pam_gnome_keyring.so use_authtok

              -session   optional     ${config.systemd.package}/lib/security/pam_systemd.so       class=greeter
              -session   optional     pam_elogind.so
              session    include      login
              -session   optional     pam_gnome_keyring.so auto_start
              -session   optional     pam_kwallet5.so      auto_start
            '';
          };
        }
      ];
    };

}
