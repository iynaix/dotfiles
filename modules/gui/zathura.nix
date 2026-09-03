{
  packages =
    { inputs, pkgs, ... }:
    {
      zathura = inputs.wrappers.wrappers.zathura.wrap {
        inherit pkgs;
        mappings = {
          "D" = "toggle_page_mode";
          "J" = "zoom out";
          "K" = "zoom in";
          "R" = "rotate";
          "d" = "scroll half-down";
          "i" = "recolor";
          "p" = "print";
          "r" = "reload";
          "u" = "scroll half-up";
        };
        settings = {
          "adjust-open" = "best-fit";
          "recolor" = true;
          "statusbar-h-padding" = 0;
          "statusbar-v-padding" = 0;
        };
      };
    };

  tags = [ "gui" ];

  config =
    { config, pkgs, ... }:
    {
      nixpkgs.overlays = [
        (_: _prev: {
          zathura = pkgs.custom.zathura.wrap {
            extraSettings = ''
              include "${config.hj.xdg.config.directory}/zathura/noctaliarc"
            '';
          };
        })
      ];

      environment.systemPackages = [
        pkgs.zathura # overlay-ed above
      ];

      xdg.mime.defaultApplications = {
        "application/pdf" = "org.pwmt.zathura.desktop";
      };

      custom.programs.print-config = {
        zathura = /* sh */ ''moor "${pkgs.zathura.configuration.constructFiles.renderedRc.outPath}"'';
      };
    };
}
