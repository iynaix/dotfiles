{
  flake.nixosModules.core =
    {
      dots,
      host,
      lib,
      pkgs,
      ...
    }:
    let
      inherit (lib) getExe hiPrio;
      customNeovim = pkgs.custom.neovim-iynaix.override { inherit dots host; };
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
        exec = ''${getExe nvim-direnv} "%F"'';
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
          (hiPrio nvim-desktop-entry)
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
