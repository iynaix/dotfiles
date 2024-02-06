{
  inputs,
  lib,
  system,
  ...
}: let
  repo_url = "https://raw.githubusercontent.com/iynaix/dotfiles";
  mkIso = nixpkgs: isoPath:
    lib.nixosSystem {
      inherit system;
      modules = [
        "${nixpkgs}/nixos/modules/installer/cd-dvd/${isoPath}.nix"
        ({pkgs, ...}: {
          environment.systemPackages =
            [
              (pkgs.writeShellApplication {
                name = "iynaixos-install";
                runtimeInputs = [pkgs.curl];
                text = ''sh <(curl -L ${repo_url}/main/install.sh)'';
              })
              (pkgs.writeShellApplication {
                name = "iynaixos-recover";
                runtimeInputs = [pkgs.curl];
                text = ''sh <(curl -L ${repo_url}/main/recover.sh)'';
              })
              (pkgs.writeShellApplication {
                name = "iynaixos-reinstall";
                runtimeInputs = [pkgs.curl];
                text = ''sh <(curl -L ${repo_url}/main/recover.sh)'';
              })
            ]
            ++ (with pkgs; [
              btop
              git
              yazi
            ]);

          programs = {
            # bye bye nano
            nano.enable = false;
            neovim = {
              enable = true;
              defaultEditor = true;
            };
          };

          # quality of lie
          nix.settings = {
            experimental-features = ["nix-command" "flakes"];
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
        })
      ];
    };
in {
  gnome-iso = mkIso inputs.nixpkgs-stable "installation-cd-graphical-calamares-gnome";
  kde-iso = mkIso inputs.nixpkgs-stable "installation-cd-graphical-calamares-plasma5";
  minimal-iso = mkIso inputs.nixpkgs-stable "installation-cd-minimal";
  gnome-iso-unstable = mkIso inputs.nixpkgs "installation-cd-graphical-calamares-gnome";
  kde-iso-unstable = mkIso inputs.nixpkgs "installation-cd-graphical-calamares-plasma5";
  minimal-iso-unstable = mkIso inputs.nixpkgs "installation-cd-minimal";
}
