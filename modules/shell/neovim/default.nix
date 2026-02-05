{
  lib,
  inputs,
  ...
}:
{
  perSystem =
    { pkgs, ... }:
    {
      packages.neovim-iynaix = pkgs.callPackage (
        {
          dots ? null,
          host ? "desktop",
        }:
        (inputs.nvf.lib.neovimConfiguration {
          inherit pkgs;
          modules = [
            ./_settings.nix
            ./_keymaps.nix
          ];
          extraSpecialArgs = { inherit dots host; };
        }).neovim
      ) { };
    };

  flake.nixosModules.core =
    { config, pkgs, ... }:
    let
      inherit (config.custom.constants) dots host;
      customNeovim = pkgs.custom.neovim-iynaix.override {
        inherit dots host;
      };
      nvim-direnv = pkgs.writeShellApplication {
        name = "nvim-direnv";
        runtimeInputs = [ pkgs.direnv ];
        text = /* sh */ ''
          if ! direnv exec "$(dirname "$1")" nvim "$@"; then
              nvim "$@"
          fi
        '';
      };
      nvim-desktop-entry = pkgs.makeDesktopItem {
        name = "Neovim";
        desktopName = "Neovim";
        genericName = "Text Editor";
        icon = "nvim";
        terminal = true;
        # load direnv before opening nvim
        exec = ''${lib.getExe nvim-direnv} "%F"'';
      };
    in
    {
      environment = {
        shellAliases = {
          nano = "nvim";
          neovim = "nvim";
          v = "nvim";
        };

        systemPackages = [
          customNeovim
          nvim-direnv
          # add the new desktop entry
          (lib.hiPrio nvim-desktop-entry)
        ];
      };

      xdg = {
        mime = {
          defaultApplications = {
            "text/plain" = "nvim.desktop";
            "text/markdown" = "nvim.desktop";
            "text/x-nix" = "nvim.desktop";
            "application/x-shellscript" = "nvim.desktop";
            "application/xml" = "nvim.desktop";
          };
          addedAssociations = {
            "text/csv" = "nvim.desktop";
          };
        };
      };

      custom.programs.print-config = {
        neovim = /* sh */ "nvf-print-config";
        nvf = /* sh */ "nvf-print-config";
      };

      custom.persist = {
        home.directories = [
          ".local/share/nvim" # data directory
          ".local/state/nvim" # persistent session info
          ".supermaven"
          ".local/share/supermaven"
        ];
      };
    };
}
