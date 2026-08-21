{
  packages =
    { inputs, pkgs, ... }:
    {
      neovim-iynaix = pkgs.callPackage (
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

  config =
    {
      config,
      host,
      lib,
      pkgs,
      ...
    }:
    let
      customNeovim = pkgs.custom.neovim-iynaix.override {
        inherit host;
        dots = "${config.hj.directory}/projects/dotfiles";
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
