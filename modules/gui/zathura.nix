{
  inputs,
  lib,
  self,
  ...
}:
let
  zathuraOptions = {
    extraSettings = lib.mkOption {
      type = lib.types.str;
      default = "";
      description = ''
        Extra settings to add to {file}`zathurarc` file.
        See <https://man.archlinux.org/man/zathurarc.5> for options.
      '';
    };
  };
in
{
  flake.wrapperModules.zathura = inputs.wrappers.lib.wrapModule (
    { config, ... }:
    let
      zathuraConf = config.pkgs.writeTextFile {
        name = "zathurarc";
        destination = "/zathurarc"; # zathura expects a directory
        text = ''
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

          ${config.extraSettings}
        '';
      };
    in
    {
      options = zathuraOptions;

      config.package = lib.mkDefault config.pkgs.zathura;
      config.flags = {
        "--config-dir" = toString zathuraConf;
      };
    }
  );

  perSystem =
    { pkgs, ... }:
    {
      packages.zathura = (self.wrapperModules.zathura.apply { inherit pkgs; }).wrapper;
    };

  flake.nixosModules.core = {
    options.custom = {
      programs.zathura = zathuraOptions;
    };
  };

  flake.nixosModules.gui =
    { config, pkgs, ... }:
    let
      noctaliaColors = "${config.hj.xdg.config.directory}/zathura/noctaliarc";
    in
    {
      nixpkgs.overlays = [
        (_: prev: {
          zathura =
            (self.wrapperModules.zathura.apply {
              pkgs = prev;
              extraSettings = ''
                include ${noctaliaColors}
              '';
            }).wrapper;
        })
      ];

      environment.systemPackages = [
        pkgs.zathura # overlay-ed above
      ];

      xdg.mime.defaultApplications = {
        "application/pdf" = "org.pwmt.zathura.desktop";
      };

      custom.programs.print-config = {
        zathura = /* sh */ ''cat "${pkgs.zathura.flags."--config-dir"}/zathurarc" "${noctaliaColors}"'';
      };
    };
}
