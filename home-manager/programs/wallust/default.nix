{
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.iynaix.wallust;
in {
  # wallust is always enabled, as programs assume the generated colorschemes are in wallust cache
  config = {
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
        "wallust/wallust.toml".text =
          ''
            backend = "resized"
            color_space = "labmixed"
            threshold = ${toString cfg.threshold}
            filter = "dark16"
          ''
          # create entries
          + lib.concatStringsSep "\n" (lib.mapAttrsToList (template: {
            target,
            enable,
            ...
          }:
            if enable
            then ''
              [[entry]]
              template = "${template}"
              target = "${target}"
            ''
            else "")
          cfg.entries);
      }
      // lib.mapAttrs' (
        template: {
          text,
          onChange,
          ...
        }:
          lib.nameValuePair "wallust/${template}" {
            inherit text onChange;
          }
      )
      cfg.entries;

    iynaix.wallust.entries = {
      # misc information for nix
      "nix.json" = {
        enable = true;
        text = builtins.toJSON {
          wallpaper = "{wallpaper}";
          fallback = "${../../gits-catppuccin.jpg}";
          monitors = config.iynaix.displays;
          colorscheme = config.iynaix.wallust.colorscheme;
          persistent_workspaces = config.iynaix.waybar.persistent-workspaces;
          neofetch = {
            logo = "${../../shell/rice/nixos.png}";
            conf = "${../../shell/rice/neofetch.conf}";
          };
          # use pywal template syntax here
          special = {
            background = "{background}";
            foreground = "{foreground}";
            cursor = "{cursor}";
          };
          colors = {
            color0 = "{color0}";
            color1 = "{color1}";
            color2 = "{color2}";
            color3 = "{color3}";
            color4 = "{color4}";
            color5 = "{color5}";
            color6 = "{color6}";
            color7 = "{color7}";
            color8 = "{color8}";
            color9 = "{color9}";
            color10 = "{color10}";
            color11 = "{color11}";
            color12 = "{color12}";
            color13 = "{color13}";
            color14 = "{color14}";
            color15 = "{color15}";
          };
        };
        target = "~/.cache/wallust/nix.json";
      };
    };

    iynaix.persist = {
      cache = [
        ".cache/wallust"
      ];
    };
  };
}
