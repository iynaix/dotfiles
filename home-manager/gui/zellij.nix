{
  config,
  isNixOS,
  lib,
  ...
}:
let
  cfg = config.custom.zellij;
in
{
  options.custom = with lib; {
    zellij.enable = mkEnableOption "zellij" // {
      default = isNixOS && !config.custom.headless;
    };
  };

  config = lib.mkIf cfg.enable {
    programs.zellij = {
      enable = true;
      enableBashIntegration = false;
      enableFishIntegration = false;
      settings = {
        default_layout = "compact";
        on_force_close = "quit";
        # theme = "default";
      };
    };

    custom.wallust.templates.zellij = {
      text = ''
        themes {
          default {
            fg      "{{color0}}"
            bg      "{{color1}}"
            black   "{{foreground}}"
            red     "{{color2}}"
            green   "{{color3}}"
            yellow  "{{color4}}"
            blue    "{{color5}}"
            magenta "{{color6}}"
            cyan    "{{color8}}"
            white   "{{color9}}"
            orange  "{{color10}}"
          }
        }
      '';
      target = "${config.xdg.configHome}/zellij/themes/default.kdl";
    };
  };
}
