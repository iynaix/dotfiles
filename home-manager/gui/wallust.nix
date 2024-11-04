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
  # checks if text is a path, assumes no spaces in path
  isTemplatePath = s: (lib.hasPrefix "/" s) && !(lib.hasInfix " " s);
in
{
  options.custom = with lib; {
    wallust = {
      enable = mkEnableOption "wallust" // {
        default = !config.custom.headless;
      };
      colorscheme = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "The colorscheme to use. If null, will use the default colorscheme from the wallpaper.";
      };
      nixJson = mkOption {
        type = types.submodule { freeformType = (pkgs.formats.json { }).type; };
        default = { };
        description = "Data to be written to nix.json for use in other programs at runtime.";
      };
      templates = mkOption {
        type = types.attrsOf (
          types.submodule {
            options = {
              text = mkOption {
                type = types.str;
                description = "Content of the template file / a template path within the nix store";
              };
              target = mkOption {
                type = types.str;
                description = "Absolute path to the file to write the template (after templating), e.g. ~/.config/dunst/dunstrc";
              };
            };
          }
        );
        default = [ ];
        description = ''
          Example templates, which are just a file you wish to apply `wallust` generated colors to.
          template = "dunstrc"
        '';
      };
    };
  };

  config = {
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
          backend = "fastresize";
          color_space = "labmixed";
          check_contrast = true;
          fallback_generator = "interpolate";
          palette = "dark16";
          templates = lib.mapAttrs (
            filename:
            { target, text, ... }:
            {
              inherit target;
              template = if isTemplatePath text then text else filename;
            }
          ) cfg.templates;
        };
      }
      //
      # set xdg configFile text and on change for wallust templates
      (lib.pipe cfg.templates [
        (lib.filterAttrs (_: template: !(isTemplatePath template.text)))
        (lib.mapAttrs' (
          template: { text, ... }: lib.nameValuePair "wallust/templates/${template}" { inherit text; }
        ))
      ]);

    custom.wallust.templates = {
      # misc information for nix
      "nix.json" = {
        text = lib.strings.toJSON (
          # use pywal template syntax here
          {
            wallpaper = "{{wallpaper}}";
            fallback = "${../gits-catppuccin.jpg}";
            inherit (config.custom) monitors;
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
  };
}
