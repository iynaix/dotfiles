{
  inputs,
  lib,
  self,
  system ? "x86_64-linux",
  ...
}:
let
  repo_url = "https://raw.githubusercontent.com/iynaix/dotfiles";
  user = "nixos";
  mkIso =
    nixpkgs: home-manager: isoPath:
    # use the lib from the nixpkgs passed in, so the nixos version will be correct
    nixpkgs.lib.nixosSystem {
      inherit system;
      modules = [
        "${nixpkgs}/nixos/modules/installer/cd-dvd/${isoPath}.nix"
        home-manager.nixosModules.home-manager
        (
          { config, pkgs, ... }:
          {
            environment = {
              systemPackages =
                with pkgs;
                [
                  (pkgs.writeShellApplication {
                    name = "iynaixos-install";
                    runtimeInputs = [ pkgs.curl ];
                    text = "sh <(curl -L ${repo_url}/main/install.sh)";
                  })
                  (pkgs.writeShellApplication {
                    name = "iynaixos-recover";
                    runtimeInputs = [ pkgs.curl ];
                    text = "sh <(curl -L ${repo_url}/main/recover.sh)";
                  })
                  (pkgs.writeShellApplication {
                    name = "iynaixos-reinstall";
                    runtimeInputs = [ pkgs.curl ];
                    text = "sh <(curl -L ${repo_url}/main/recover.sh)";
                  })
                  bat
                  btop
                  eza
                  home-manager
                  tree
                  yazi
                  # custom neovim
                  self.packages.${system}.neovim-iynaix
                ]
                ++ lib.optionals (lib.hasInfix "plasma" isoPath) [ kitty ];

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
            };

            # use nmtui instead of wpa_supplicant for minimal iso
            networking.wireless.enable = false;
            networking.networkmanager.enable = true;

            # update greeting for iso to suggest networkmanager
            services.getty.helpLine =
              ''
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
            systemd.services.sshd.wantedBy = pkgs.lib.mkForce [ "multi-user.target" ];
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
        {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;

            extraSpecialArgs = {
              inherit user isoPath;
            };

            users.${user} = {
              imports = [ ./home.nix ];
            };
          };
        }
      ];
    };
in
{
  kde-iso =
    mkIso inputs.nixpkgs-stable inputs.home-manager-stable
      "installation-cd-graphical-calamares-plasma6";
  minimal-iso = mkIso inputs.nixpkgs-stable inputs.home-manager-stable "installation-cd-minimal";
  kde-iso-unstable =
    mkIso inputs.nixpkgs inputs.home-manager
      "installation-cd-graphical-calamares-plasma6";
  minimal-iso-unstable = mkIso inputs.nixpkgs inputs.home-manager "installation-cd-minimal";
}
