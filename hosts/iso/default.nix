{
  inputs,
  lib,
  system ? "x86_64-linux",
  ...
}:
let
  repo_url = "https://raw.githubusercontent.com/elias-ainsworth/dotfiles";
  user = "nixos";
  mkIso =
    nixpkgs: isoPath:
    lib.nixosSystem {
      inherit system;
      modules = [
        "${nixpkgs}/nixos/modules/installer/cd-dvd/${isoPath}.nix"
        inputs.home-manager.nixosModules.home-manager
        (
          { config, pkgs, ... }:
          {
            environment = {
              systemPackages = with pkgs; [
                (pkgs.writeShellApplication {
                  name = "elias-ainsworthos-install";
                  runtimeInputs = [ pkgs.curl ];
                  text = "sh <(curl -L ${repo_url}/main/install.sh)";
                })
                (pkgs.writeShellApplication {
                  name = "elias-ainsworthos-recover";
                  runtimeInputs = [ pkgs.curl ];
                  text = "sh <(curl -L ${repo_url}/main/recover.sh)";
                })
                (pkgs.writeShellApplication {
                  name = "elias-ainsworthos-reinstall";
                  runtimeInputs = [ pkgs.curl ];
                  text = "sh <(curl -L ${repo_url}/main/recover.sh)";
                })
                btop
                eza
                git
                home-manager
                tree
                yazi
              ];
              shellAliases = {
                eza = "eza '--icons' '--group-directories-first' '--header' '--octal-permissions' '--hyperlink'";
                ls = "eza";
                ll = "eza -l";
                la = "eza -a";
                lla = "eza -la";
                y = "yazi";
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
              neovim = {
                enable = true;
                defaultEditor = true;
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
            systemd.services.sshd.wantedBy = pkgs.lib.mkForce [ "multi-user.target" ];
            users.users.root.openssh.authorizedKeys.keyFiles = [
              ../../home-manager/id_rsa.pub
              ../../home-manager/id_ed25519.pub
            ];

            # quality of life
            nix = {
              package = pkgs.nixVersions.latest;
              settings = {
                experimental-features = [
                  "nix-command"
                  "flakes"
                  # "repl-flake"
                ];
                substituters = [
                  "https://hyprland.cachix.org"
                  "https://nix-community.cachix.org"
                  "https://ghostty.cachix.org"
                ];
                trusted-public-keys = [
                  "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc="
                  "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
                  "ghostty.cachix.org-1:QB389yTa6gTyneehvqG58y0WnHjQOqgnA+wBnpWWxns="
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
  kde-iso = mkIso inputs.nixpkgs-stable "installation-cd-graphical-calamares-plasma5";
  minimal-iso = mkIso inputs.nixpkgs-stable "installation-cd-minimal";
  kde-iso-unstable = mkIso inputs.nixpkgs "installation-cd-graphical-calamares-plasma5";
  minimal-iso-unstable = mkIso inputs.nixpkgs "installation-cd-minimal";
}
