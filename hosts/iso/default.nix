{
  inputs,
  lib,
  system ? "x86_64-linux",
  ...
}:
let
  repo_url = "https://raw.githubusercontent.com/iynaix/dotfiles";
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
                ]
                ++ (with pkgs; [
                  btop
                  git
                  eza
                  home-manager
                  yazi
                ]);
              shellAliases = {
                eza = "eza '--icons' '--group-directories-first' '--header' '--octal-permissions' '--hyperlink'";
                ls = "eza";
                ll = "eza -l";
                la = "eza -a";
                lla = "eza -la";
                t = "eza -la --git-ignore --icons --tree --hyperlink --level 3";
                tree = "eza -la --git-ignore --icons --tree --hyperlink --level 3";
                y = "yazi";
              };
            };

            programs = {
              # bye bye nano
              nano.enable = false;
              neovim = {
                enable = true;
                defaultEditor = true;
              };
            };

            # enable SSH in the boot process.
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

            # set dark theme for kde, adapted from plasma-manager
            home-manager = {
              useGlobalPkgs = true;
              useUserPackages = true;

              users.${user} = {
                home = {
                  username = user;
                  homeDirectory = "/home/${user}";
                  stateVersion = "24.05";
                };

                xdg.configFile."autostart/plasma-dark-mode.desktop".text =
                  let
                    plasmaDarkMode = pkgs.writeShellScriptBin "plasma-dark-mode" ''
                      plasma-apply-lookandfeel -a org.kde.breezedark.desktop
                      plasma-apply-desktoptheme breeze-dark
                    '';
                  in
                  lib.mkIf (lib.hasInfix "kde" isoPath) ''
                    [Desktop Entry]
                    Type=Application
                    Name=Plasma Dark Mode
                    Exec=${lib.getExe plasmaDarkMode}
                    X-KDE-autostart-condition=ksmserver
                  '';
              };
            };
          }
        )
      ];
    };
in
{
  kde-iso-stable = mkIso inputs.nixpkgs-stable "installation-cd-graphical-calamares-plasma5";
  minimal-iso-stable = mkIso inputs.nixpkgs-stable "installation-cd-minimal";
  kde-iso-unstable = mkIso inputs.nixpkgs "installation-cd-graphical-calamares-plasma5";
  minimal-iso-unstable = mkIso inputs.nixpkgs "installation-cd-minimal";
}
