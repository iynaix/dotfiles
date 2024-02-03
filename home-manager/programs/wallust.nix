{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.custom.wallust;
  tomlFormat = pkgs.formats.toml {};
in {
  # wallust is always enabled, as programs assume the generated colorschemes are in wallust cache
  home.packages = [pkgs.wallust];

  xdg.configFile =
    {
      # add custom themes in pywal format
      "wallust/themes" = {
        source = ./wallust;
        recursive = true;
      };
      "wallust/wallust.toml".source = tomlFormat.generate "wallust-toml" {
        backend = "resized";
        color_space = "labmixed";
        threshold = 20;
        palette = "dark16";
        templates = lib.mapAttrs (filename: {
          target,
          enable,
          ...
        }:
          lib.optionalAttrs enable {
            inherit target;
            template = filename;
            new_engine = true;
          })
        cfg.templates;
      };
    }
    //
    # set xdg configFile text and on change for wallust templates
    (lib.mapAttrs' (
        template: {text, ...}: lib.nameValuePair "wallust/${template}" {inherit text;}
      )
      cfg.templates);

  custom.wallust.templates = {
    # misc information for nix
    "nix.json" = {
      enable = true;
      text = lib.strings.toJSON {
        wallpaper = "{{wallpaper}}";
        fallback = "${../gits-catppuccin.jpg}";
        monitors = config.custom.displays;
        inherit (config.custom.wallust) colorscheme;
        persistent_workspaces = config.custom.waybar.persistent-workspaces;
        # use pywal template syntax here
        special = {
          background = "{{background}}";
          foreground = "{{foreground}}";
          cursor = "{{cursor}}";
        };
        colors = lib.listToAttrs (map (i: {
          name = "color${toString i}";
          value = "{{color${toString i}}}";
        }) (lib.range 0 15));
      };
      target = "${config.xdg.cacheHome}/wallust/nix.json";
    };
  };

  custom.persist = {
    home = {
      cache = [
        ".cache/wallust"
      ];
    };
  };
}
