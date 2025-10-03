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
    range
    ;
  inherit (lib.strings) toJSON;
  inherit (lib.types)
    attrsOf
    nullOr
    str
    submodule
    ;
  cfg = config.custom.programs.wallust;
  tomlFormat = pkgs.formats.toml { };
  # checks if text is a path, assumes no spaces in path
  isTemplatePath = s: (hasPrefix "/" s) && !(hasInfix " " s);
  wallustConf = {
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
in
{
  options.custom = {
    programs.wallust = {
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

  # wallust is always enabled, as programs assume the generated colorschemes are in wallust cache
  config = {
    environment.systemPackages = [ pkgs.wallust ];

    hj.xdg.config.files = {
      "wallust/wallust.toml".source = tomlFormat.generate "wallust.toml" wallustConf;
    }
    // (
      cfg.templates
      |> filterAttrs (_: template: !(isTemplatePath template.text))
      |> mapAttrs' (
        template: { text, ... }: nameValuePair "wallust/templates/${template}" { inherit text; }
      )
    );

    # setup wallust colorschemes for shells
    programs = {
      bash.interactiveShellInit = mkIf config.custom.programs.wallust.enable ''
        wallust_colors="${config.hj.xdg.cache.directory}/wallust/sequences"
        if [ -e "$wallust_colors" ]; then
          command cat "$wallust_colors"
        fi
      '';

      fish.interactiveShellInit = mkIf config.custom.programs.wallust.enable ''
        set wallust_colors "${config.hj.xdg.cache.directory}/wallust/sequences"
        if test -e "$wallust_colors"
            command cat "$wallust_colors"
        end
      '';
    };

    custom.programs.wallust.templates = {
      # misc information for nix
      "nix.json" = {
        text = toJSON (
          # use pywal template syntax here
          {
            wallpaper = "{{wallpaper}}";
            fallback = "${../../wallpaper-default.jpg}";
            inherit (config.custom.hardware) monitors;
            inherit (config.custom.programs.wallust) colorscheme;
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
        target = "${config.hj.xdg.cache.directory}/wallust/nix.json";
      };
    };
  };
}
