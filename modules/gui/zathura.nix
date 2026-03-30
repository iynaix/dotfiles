{
  inputs,
  ...
}:
let
  baseZathuraConf = {
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
      "page-padding" = 1;
      "recolor" = true;
      "statusbar-h-padding" = 0;
      "statusbar-v-padding" = 0;
    };
  };
in
{
  perSystem =
    { pkgs, ... }:
    {
      packages.zathura = inputs.wrappers.wrappers.zathura.wrap ({ inherit pkgs; } // baseZathuraConf);
    };

  flake.modules.nixos.gui =
    { config, pkgs, ... }:
    let
      noctaliaColors = "${config.hj.xdg.config.directory}/zathura/noctaliarc";
    in
    {
      nixpkgs.overlays = [
        (_: prev: {
          zathura = inputs.wrappers.wrappers.zathura.wrap {
            pkgs = prev;
            extraSettings = ''
              include "${noctaliaColors}"
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
        zathura = /* sh */ ''cat "${
          pkgs.zathura.configuration.flags."--config-dir".data
        }/zathurarc" "${noctaliaColors}" | moor'';
      };
    };
}
