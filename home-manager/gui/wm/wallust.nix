{
  config,
  host,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    filterAttrs
    hasInfix
    hasPrefix
    listToAttrs
    mapAttrs
    mapAttrs'
    mkEnableOption
    mkIf
    mkOption
    nameValuePair
    pipe
    range
    ;
  inherit (lib.strings) toJSON;
  inherit (lib.types)
    attrsOf
    nullOr
    str
    submodule
    ;
  cfg = config.custom.wallust;
  # checks if text is a path, assumes no spaces in path
  isTemplatePath = s: (hasPrefix "/" s) && !(hasInfix " " s);
in
{
  options.custom = {
    wallust = {
      enable = mkEnableOption "wallust" // {
        default = config.custom.wm != "tty";
      };
      colorscheme = mkOption {
        type = nullOr str;
        default = null;
        description = "The colorscheme to use. If null, will use the default colorscheme from the wallpaper.";
      };
      nixJson = mkOption {
        type = submodule { freeformType = (pkgs.formats.json { }).type; };
        default = { };
        description = "Data to be written to nix.json for use in other programs at runtime.";
      };
      templates = mkOption {
        type = attrsOf (submodule {
          options = {
            text = mkOption {
              type = str;
              description = "Content of the template file / a template path within the nix store";
            };
            target = mkOption {
              type = str;
              description = "Absolute path to the file to write the template (after templating), e.g. ~/.config/dunst/dunstrc";
            };
          };
        });
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
    programs = {
      wallust = {
        enable = true;
        settings = {
          backend = "fastresize";
          color_space = "lab";
          check_contrast = true;
          fallback_generator = "interpolate";
          palette = "dark16";
          templates = mapAttrs (
            filename:
            { target, text, ... }:
            {
              inherit target;
              template = if isTemplatePath text then text else filename;
            }
          ) cfg.templates;
        };
      };

      # setup wallust colorschemes for shells
      bash.initExtra = mkIf config.custom.wallust.enable ''
        wallust_colors="${config.xdg.cacheHome}/wallust/sequences"
        if [ -e "$wallust_colors" ]; then
          command cat "$wallust_colors"
        fi
      '';

      fish.shellInit = mkIf config.custom.wallust.enable ''
        set wallust_colors "${config.xdg.cacheHome}/wallust/sequences"
        if test -e "$wallust_colors"
            command cat "$wallust_colors"
        end
      '';
    };

    # set xdg configFile text and on change for wallust templates
    xdg.configFile = pipe cfg.templates [
      (filterAttrs (_: template: !(isTemplatePath template.text)))
      (mapAttrs' (
        template: { text, ... }: nameValuePair "wallust/templates/${template}" { inherit text; }
      ))
    ];

    custom.wallust.templates = {
      # misc information for nix
      "nix.json" = {
        text = toJSON (
          # use pywal template syntax here
          {
            wallpaper = "{{wallpaper}}";
            fallback = "${../../wallpaper-default.jpg}";
            inherit (config.custom) monitors;
            inherit (config.custom.wallust) colorscheme;
            inherit host;
            special = {
              background = "{{background}}";
              foreground = "{{foreground}}";
              cursor = "{{cursor}}";
            };
            colors = listToAttrs (
              map (i: {
                name = "color${toString i}";
                value = "{{color${toString i}}}";
              }) (range 0 15)
            );
          }
          // cfg.nixJson
        );
        target = "${config.xdg.cacheHome}/wallust/nix.json";
      };
    };
  };
}
