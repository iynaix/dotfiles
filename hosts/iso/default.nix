{
  inputs,
  self,
  system ? "x86_64-linux",
  ...
}:
let
  inherit (self) lib;
  repo_url = "https://raw.githubusercontent.com/iynaix/dotfiles";
  mkIso =
    nixpkgs: isoPath:
    # use the lib from the nixpkgs passed in, so the nixos version will be correct
    nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        "${nixpkgs}/nixos/modules/installer/cd-dvd/${isoPath}.nix"
        (
          { config, pkgs, ... }:
          {
            # add memtest to the boot menu
            boot.loader.grub.memtest86.enable = true;
            isoImage.makeBiosBootable = true;

            environment = {
              systemPackages =
                with pkgs;
                [
                  (pkgs.writeShellApplication {
                    name = "iynaixos-install";
                    runtimeInputs = [ pkgs.curl ];
                    text = # sh
                      "sh <(curl -L ${repo_url}/main/install.sh)";
                  })
                  (pkgs.writeShellApplication {
                    name = "iynaixos-recover";
                    runtimeInputs = [ pkgs.curl ];
                    text = # sh
                      "sh <(curl -L ${repo_url}/main/recover.sh)";
                  })
                  (pkgs.writeShellApplication {
                    name = "iynaixos-reinstall";
                    runtimeInputs = [ pkgs.curl ];
                    text = # sh
                      "sh <(curl -L ${repo_url}/main/recover.sh)";
                  })
                  bat
                  btop
                  eza
                  tree
                  # custom neovim
                  self.packages.${system}.neovim-iynaix
                ]
                ++ lib.optionals (lib.hasInfix "plasma" isoPath) [ ghostty ];

              variables = {
                EDITOR = "nvim";
                VISUAL = "nvim";
                NIXPKGS_ALLOW_UNFREE = "1";
              };

              shellAliases = {
                cat = "bat";
                ccat = "command cat";
                eza = "eza '--icons' '--group-directories-first' '--header' '--octal-permissions' '--hyperlink'";
                ls = "eza";
                ll = "eza -l";
                la = "eza -a";
                lla = "eza -la";
                y = "yazi";
                nano = "nvim";
                neovim = "nvim";
                v = "nvim";
              };

              # set dark theme for kde, adapted from plasma-manager
              etc."xdg/autostart/plasma-dark-mode.desktop" = lib.mkIf (lib.hasInfix "plasma" isoPath) {
                text = ''
                  [Desktop Entry]
                  Type=Application
                  Name=Plasma Dark Mode
                  Exec=${pkgs.writeShellScript "plasma-dark-mode" ''
                    plasma-apply-lookandfeel -a org.kde.breezedark.desktop
                    plasma-apply-desktoptheme breeze-dark
                  ''}
                  X-KDE-autostart-condition=ksmserver
                '';
              };
            };

            # use nmtui instead of wpa_supplicant for minimal iso
            networking.wireless.enable = false;
            networking.networkmanager.enable = true;

            # update greeting for iso to suggest networkmanager
            services.getty.helpLine = ''
              The "nixos" and "root" accounts have empty passwords.

              To log in over ssh you must set a password for either "nixos" or "root"
              with `passwd` (prefix with `sudo` for "root"), or add your public key to
              /home/nixos/.ssh/authorized_keys or /root/.ssh/authorized_keys.

              If you need a wireless connection, use `nmtui`.
            ''
            + lib.optionalString config.services.xserver.enable ''
              Type `sudo systemctl start display-manager' to
              start the graphical user interface.
            '';

            programs = {
              # bye bye nano
              nano.enable = false;

              # better defaults for yazi
              yazi = {
                enable = true;

                settings = {
                  yazi = {
                    mgr = {
                      ratio = [
                        0
                        1
                        1
                      ];
                      sort_by = "alphabetical";
                      sort_sensitive = false;
                      sort_reverse = false;
                      linemode = "size";
                      show_hidden = true;
                    };
                  };

                  theme = {
                    mgr = {
                      preview_hovered = {
                        underline = false;
                      };
                      folder_offset = [
                        1
                        0
                        1
                        0
                      ];
                      preview_offset = [
                        1
                        1
                        1
                        1
                      ];
                    };
                  };
                };
              };
            };

            # enable SSH in the boot process.
            services.openssh = {
              enable = true;
              # disable password auth
              settings = {
                PasswordAuthentication = false;
                KbdInteractiveAuthentication = false;
              };
            };
            systemd.services.sshd.wantedBy = lib.mkForce [ "multi-user.target" ];
            users.users.root.openssh.authorizedKeys.keyFiles = [
              ../../home-manager/id_rsa.pub
              ../../home-manager/id_ed25519.pub
            ];

            # quality of life
            nix = {
              package = pkgs.nixVersions.latest;
              registry = {
                nixos-unstable = {
                  from = {
                    type = "indirect";
                    id = "nixos-unstable";
                  };
                  to = {
                    type = "github";
                    owner = "NixOS";
                    repo = "nixpkgs";
                    rev = "nixos-unstable";
                  };
                };
              };
              settings = {
                experimental-features = [
                  "nix-command"
                  "flakes"
                  "pipe-operators"
                ];
                substituters = [
                  "https://nix-community.cachix.org"
                ];
                trusted-public-keys = [
                  "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
                ];
              };
            };
          }
        )
      ];
    };
in
{
  kde-iso = mkIso inputs.nixpkgs-stable "installation-cd-graphical-calamares-plasma6";
  minimal-iso = mkIso inputs.nixpkgs-stable "installation-cd-minimal";
  kde-iso-unstable = mkIso inputs.nixpkgs "installation-cd-graphical-calamares-plasma6";
  minimal-iso-unstable = mkIso inputs.nixpkgs "installation-cd-minimal";
}
