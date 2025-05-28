{
  config,
  dots,
  host,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) getExe;
  customNeovim = pkgs.custom.neovim-iynaix.override { inherit dots host; };
  nvim-direnv = pkgs.writeShellApplication {
    name = "nvim-direnv";
    runtimeInputs = [
      config.programs.direnv.package
      customNeovim
    ];
    text = # sh
      ''
        if ! direnv exec "$(dirname "$1")" nvim "$@"; then
            nvim "$@"
        fi
      '';
  };
in
{
  home = {
    packages = [
      customNeovim
      nvim-direnv
    ];

    shellAliases = {
      nano = "nvim";
      neovim = "nvim";
      v = "nvim";
    };
  };

  xdg = {
    desktopEntries.nvim = {
      name = "Neovim";
      genericName = "Text Editor";
      icon = "nvim";
      terminal = true;
      # load direnv before opening nvim
      exec = ''${getExe nvim-direnv} "%F"'';
    };

    mimeApps = {
      defaultApplications = {
        "text/plain" = "nvim.desktop";
        "application/x-shellscript" = "nvim.desktop";
        "application/xml" = "nvim.desktop";
      };
      associations.added = {
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
}
