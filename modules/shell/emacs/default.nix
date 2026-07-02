{
  flake.modules.nixos.core =
    { config, pkgs, ... }:
    {
      services.emacs = {
        enable = true;
        package = pkgs.emacs-pgtk;
      };

      # add doom to path
      environment.sessionVariables = {
        PATH = [ "$HOME/.config/emacs/bin" ];
        DOOMDIR = "${config.custom.constants.dots}/modules/shell/emacs/doom";
      };

      custom.persist = {
        home = {
          directories = [
            ".config/emacs"
          ];
        };
      };
    };
}
