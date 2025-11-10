{ inputs, ... }:
{
  perSystem =
    { pkgs, ... }:
    let
      # generated using `wallust theme Tokyo-Night`
      zathuraColors = ''
        set default-bg                  "#414868"
        set default-fg                  "#F7768E"

        set statusbar-fg                "#7AA2F7"
        set statusbar-bg                "#9ECE6A"

        set inputbar-bg                 "#414868"
        set inputbar-fg                 "#A9B1D6"

        set notification-bg             "#414868"
        set notification-fg             "#A9B1D6"

        set notification-error-bg       "#414868"
        set notification-error-fg       "#414868"

        set notification-warning-bg     "#414868"
        set notification-warning-fg     "#414868"

        set highlight-color             "rgba(158,206,106,0.5)"
        set highlight-active-color      "rgba(187,154,247,0.5)"

        set completion-bg               "#F7768E"
        set completion-fg               "#BB9AF7"

        set completion-highlight-fg     "#A9B1D6"
        set completion-highlight-bg     "#BB9AF7"

        set recolor-lightcolor          "#414868"
        set recolor-darkcolor           "#7DCFFF"
      '';
      zathuraConf = pkgs.writeTextFile {
        name = "zathurarc";
        text = ''
          ${zathuraColors}

          set adjust-open	"best-fit"
          set page-padding	"1"
          set recolor	"true"
          set statusbar-h-padding	"0"
          set statusbar-v-padding	"0"
          map D   toggle_page_mode
          map J   zoom out
          map K   zoom in
          map R   rotate
          map d   scroll half-down
          map i   recolor
          map p   print
          map r   reload
          map u   scroll half-up
        '';
        destination = "/zathurarc";
      };
    in
    {
      packages.zathura' = inputs.wrappers.lib.wrapPackage {
        inherit pkgs;
        package = pkgs.zathura;
        flags = {
          "--config-dir" = zathuraConf;
        };
      };
    };

  flake.nixosModules.gui =
    { pkgs, self, ... }:
    {
      nixpkgs.overlays = [
        (_: _prev: {
          zathura = self.packages.${pkgs.stdenv.hostPlatform.system}.zathura';
        })
      ];

      environment.systemPackages = [
        pkgs.zathura # overlay-ed above
      ];

      xdg.mime.defaultApplications = {
        "application/pdf" = "org.pwmt.zathura.desktop";
      };
    };
}
