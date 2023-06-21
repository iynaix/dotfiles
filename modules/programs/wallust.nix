{
  user,
  pkgs,
  lib,
  config,
  ...
}: let
  cfg = config.iynaix.wallust;
in {
  options.iynaix.wallust = with lib.types; {
    enable = lib.mkEnableOption "wallust" // {default = true;};
    threshold = lib.mkOption {
      type = int;
      default = 11;
    };

    entries = lib.mkOption {
      type = attrsOf (submodule {
        options = {
          enable = lib.mkOption {
            type = bool;
            default = false;
            description = "Enable this entry";
          };
          text = lib.mkOption {
            type = str;
            description = "Content of the template file";
          };
          target = lib.mkOption {
            type = str;
            description = "Absolute path to the file to write the template (after templating), e.g. ~/.config/dunst/dunstrc";
          };
        };
      });
      default = [];
      description = ''
        Example entries, which are just a file you wish to apply `wallust` generated colors to.
        template = "dunstrc"
      '';
    };

    # enable wallust for individual programs
    dunst = lib.mkEnableOption "dunst" // {default = cfg.enable;};
    waybar = lib.mkEnableOption "waybar" // {default = cfg.enable;};
    swaylock = lib.mkEnableOption "swaylock" // {default = cfg.enable;};
    rofi = lib.mkEnableOption "rofi" // {default = cfg.enable;};
    zathura = lib.mkEnableOption "zathura" // {default = cfg.enable;};
    wezterm = lib.mkEnableOption "wezterm" // {default = cfg.enable;};
  };

  config = {
    home-manager.users.${user} = {
      home.packages = [pkgs.wallust];

      # wallust config
      xdg.configFile =
        {
          "wallust/wallust.toml".text =
            ''
              # How the image is parse, in order to get the colors:
              #  * full    - reads the whole image (more precision, slower)
              #  * resized - resizes the image to 1/4th of the original, before parsing it (more color mixing, faster)
              #  * thumb   - fast algo hardcoded to 512x512 (faster than resized)
              #  * wal     - uses image magick `convert` to read the image (less colors)
              backend = "full"

              # What color space to use to produce and select the most prominent colors:
              #  * lab      - use CIEL*a*b color space
              #  * labmixed - variant of lab that mixes colors, if not enough colors it fallbacks to usual lab,
              # for that reason is not recommended in small images
              color_space = "labmixed"

              # Difference between similar colors, used by the colorspace:
              #  <= 1       Not perceptible by human eyes.
              #  1 - 2      Perceptible through close observation.
              #  2 - 10     Perceptible at a glance.
              #  11 - 49    Colors are more similar than opposite
              #  100        Colors are exact opposite
              threshold = ${toString cfg.threshold}

              # Use the most prominent colors in a way that makes sense, a scheme:
              #  * dark    - 8 dark colors, color0 darkest - color7 lightest, dark background light contrast
              #  * dark16  - same as dark but it displays 16 colors
              #  * light   - 8 light colors, color0 lightest - color7 darkest, light background dark contrast
              #  * light16 - same as light but displays 16 colors
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
          template: {text, ...}:
            lib.nameValuePair "wallust/${template}" {
              text = text;
            }
        )
        cfg.entries;
    };

    iynaix.persist.home.directories = [
      ".config/wallust"
      ".cache/wallust"
    ];
  };
}
