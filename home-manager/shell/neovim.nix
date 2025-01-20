{
  config,
  lib,
  pkgs,
  ...
}:
let
  customNeovim = pkgs.custom.neovim-iynaix;
  nvim-with-direnv = pkgs.writeShellApplication {
    name = "nvim-with-direnv";
    runtimeInputs = [
      config.programs.direnv.package
      customNeovim
    ];
    text = ''
      git_root=$(git -C "$(dirname "$1")" rev-parse --show-toplevel 2>/dev/null || echo "$1")

      if git -C "$(dirname "$1")" rev-parse --git-dir >/dev/null 2>&1; then
          direnv exec "$git_root" nvim "$@"
      else
          nvim "$@"
      fi
    '';
  };
in
{
  home = {
    packages = [ customNeovim ];

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
      exec = "${lib.getExe nvim-with-direnv} %f";
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
