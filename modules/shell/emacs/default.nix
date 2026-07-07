{ lib, ... }: {
  flake.modules.nixos.core =
    { config, pkgs, ... }:
    {
      services.emacs = {
        enable = true;
        package = (pkgs.emacsPackagesFor pkgs.emacs-pgtk).emacsWithPackages (epkgs: [
          epkgs.vterm
          epkgs.treesit-grammars.with-all-grammars
        ]);
      };

      # add doom to path
      environment.sessionVariables = {
        PATH = [ "$HOME/.config/emacs/bin" ];
        DOOMDIR = "${config.custom.constants.dots}/modules/shell/emacs/doom";
      };

      system.userActivationScripts = {
        # installation script on rebuild, should be used
        doomEmacs = {
          text = ''
            EMACS="${config.hj.xdg.config.directory}/emacs"

            if [ ! -f "$EMACS/bin/doom" ]; then
              ${lib.getExe pkgs.git} clone https://github.com/hlissner/doom-emacs.git $EMACS
              yes | $EMACS/bin/doom install
              $EMACS/bin/doom sync
            fi
          '';
        };
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
