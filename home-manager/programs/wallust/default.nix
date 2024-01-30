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

  # wallust config
  xdg.configFile =
    {
      # custom themes in pywal format
      "wallust/catppuccin-frappe.json".source = ./catppuccin-frappe.json;
      "wallust/catppuccin-macchiato.json".source = ./catppuccin-macchiato.json;
      "wallust/catppuccin-mocha.json".source = ./catppuccin-mocha.json;
      "wallust/decay-dark.json".source = ./decay-dark.json;
      "wallust/night-owl.json".source = ./night-owl.json;
      "wallust/tokyo-night.json".source = ./tokyo-night.json;

      # wallust config
      "wallust/wallust.toml".source = tomlFormat.generate "wallust-toml" {
        backend = "resized";
        color_space = "labmixed";
        inherit (cfg) threshold;
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
    # set xdg configFile text and on change for wallust templates
    // lib.mapAttrs' (
      template: {text, ...}:
        lib.nameValuePair "wallust/${template}" {inherit text;}
    )
    cfg.templates;

  custom.wallust.templates = {
    # misc information for nix
    "nix.json" = {
      enable = true;
      text = lib.strings.toJSON {
        wallpaper = "{wallpaper}";
        fallback = "${../../gits-catppuccin.jpg}";
        monitors = config.custom.displays;
        inherit (config.custom.wallust) colorscheme;
        persistent_workspaces = config.custom.waybar.persistent-workspaces;
        # use pywal template syntax here
        special = {
          background = "{{background}}";
          foreground = "{{foreground}}";
          cursor = "{{cursor}}";
        };
        colors = lib.pipe (lib.range 0 15) [
          (map (i: {
            name = "color${toString i}";
            value = "{{color${toString i}}}";
          }))
          lib.listToAttrs
        ];
      };
      target = "${config.xdg.cacheHome}/wallust/nix.json";
    };
  };

  custom.persist = {
    cache = [
      ".cache/wallust"
    ];
  };
}
