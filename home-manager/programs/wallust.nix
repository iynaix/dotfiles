{
  config,
  host,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.custom.wallust;
  tomlFormat = pkgs.formats.toml { };
in
{
  # wallust is always enabled, as programs assume the generated colorschemes are in wallust cache
  home.packages = [ pkgs.wallust ];

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
        check_contrast = true;
        fallback_generator = "interpolate";
        palette = "dark16";
        templates = lib.mapAttrs (
          filename:
          { target, ... }:
          {
            inherit target;
            template = filename;
            new_engine = true;
          }
        ) cfg.templates;
      };
    }
    //
    # set xdg configFile text and on change for wallust templates
    (lib.mapAttrs' (
      template: { text, ... }: lib.nameValuePair "wallust/${template}" { inherit text; }
    ) cfg.templates);

  custom.wallust.templates = {
    # misc information for nix
    "nix.json" = {
      text = lib.strings.toJSON (
        # use pywal template syntax here
        {
          wallpaper = "{{wallpaper}}";
          fallback = "${../gits-catppuccin.jpg}";
          monitors = config.custom.displays;
          inherit (config.custom.wallust) colorscheme;
          inherit host;
          special = {
            background = "{{background}}";
            foreground = "{{foreground}}";
            cursor = "{{cursor}}";
          };
          colors = lib.listToAttrs (
            map (i: {
              name = "color${toString i}";
              value = "{{color${toString i}}}";
            }) (lib.range 0 15)
          );
        }
        // cfg.nixJson
      );
      target = "${config.xdg.cacheHome}/wallust/nix.json";
    };
  };

  # setup wallust colorschemes for shells
  programs = {
    bash.initExtra = lib.mkIf config.custom.wallust.enable ''
      wallust_colors="${config.xdg.cacheHome}/wallust/sequences"
      if [ -e "$wallust_colors" ]; then
        command cat "$wallust_colors"
      fi
    '';

    fish.shellInit = lib.mkIf config.custom.wallust.enable ''
      set wallust_colors "${config.xdg.cacheHome}/wallust/sequences"
      if test -e "$wallust_colors"
          command cat "$wallust_colors"
      end
    '';
  };

  custom.persist = {
    home = {
      cache = [ ".cache/wallust" ];
    };
  };
}
