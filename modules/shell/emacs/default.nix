{
  flake.modules.nixos.core =
    { config, pkgs, ... }:
    let
      doom-install = pkgs.writeShellApplication {
        name = "doom-install";
        runtimeInputs = [ config.programs.git.package ];
        text = ''
          EMACS="${config.hj.xdg.config.directory}/emacs"

          if [ ! -f "$EMACS/bin/doom" ]; then
            git clone https://github.com/hlissner/doom-emacs.git $EMACS
            yes | $EMACS/bin/doom install
            $EMACS/bin/doom sync
          fi
        '';
      };
    in
    {
      services.emacs = {
        enable = true;
        package = (pkgs.emacsPackagesFor pkgs.emacs-pgtk).emacsWithPackages (epkgs: [
          epkgs.vterm
          epkgs.treesit-grammars.with-all-grammars
        ]);
      };

      # add doom to path
      environment = {
        sessionVariables = {
          PATH = [ "$HOME/.config/emacs/bin" ];
          DOOMDIR = "${config.custom.constants.dots}/modules/shell/emacs/doom";
        };

        systemPackages = [
          doom-install
        ];
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
