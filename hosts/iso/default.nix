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
          { pkgs, ... }:
          {
            environment = {
              systemPackages =
                [
                  (pkgs.writeShellApplication {
                    name = "thorneos-install";
                    runtimeInputs = [ pkgs.curl ];
                    text = "sh <(curl -L ${repo_url}/main/install.sh)";
                  })
                  (pkgs.writeShellApplication {
                    name = "thorneos-recover";
                    runtimeInputs = [ pkgs.curl ];
                    text = "sh <(curl -L ${repo_url}/main/recover.sh)";
                  })
                  (pkgs.writeShellApplication {
                    name = "thorneos-reinstall";
                    runtimeInputs = [ pkgs.curl ];
                    text = "sh <(curl -L ${repo_url}/main/recover.sh)";
                  })
                ]
                ++ (with pkgs; [
                  btop
                  eza
                  git
                  home-manager
                  tree
                  yazi
                ]);
              shellAliases = {
                eza = "eza '--icons' '--group-directories-first' '--header' '--octal-permissions' '--hyperlink'";
                ls = "eza";
                ll = "eza -l";
                la = "eza -a";
                lla = "eza -la";
                y = "yazi";
              };
            };

            programs = {
              # bye bye nano
              nano.enable = false;
              helix = {
                enable = true;
                defaultEditor = true;
              };
              neovim = {
                enable = true;
                # defaultEditor = true;
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
              package = pkgs.lix;
              settings = {
                experimental-features = [
                  "nix-command"
                  "flakes"
                  "repl-flake"
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
  kde-iso-stable = mkIso inputs.nixpkgs-stable "installation-cd-graphical-calamares-plasma5";
  minimal-iso-stable = mkIso inputs.nixpkgs-stable "installation-cd-minimal";
  kde-iso-unstable = mkIso inputs.nixpkgs "installation-cd-graphical-calamares-plasma5";
  minimal-iso-unstable = mkIso inputs.nixpkgs "installation-cd-minimal";
}
