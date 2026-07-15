{
  inputs,
  lib,
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

  flake.modules.nixos.core =
    { config, pkgs, ... }:
    let
      inherit (config.custom.constants) dots host;
      customNeovim = pkgs.custom.neovim-iynaix.override {
        inherit dots host;
      };
    in
    {
      environment = {
        systemPackages = [
          customNeovim
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

      custom.programs.print-config = rec {
        neovim = /* sh */ "nvf-print-config | ${lib.getExe pkgs.stylua} --indent-type Spaces --indent-width 2 - | moor --lang lua";
        nvf = neovim;
        nvim = neovim;
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
