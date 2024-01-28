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
