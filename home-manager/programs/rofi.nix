{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.iynaix.rofi;
  rofiThemes = "${pkgs.iynaix.rofi-themes}/files";
  launcherType = 2;
  launcherStyle = 2;
  menuType = 2;
  menuStyle = 1;
  powermenuType = 4;
  powermenuStyle = 3;
  powermenuDir = "${rofiThemes}/powermenu/type-${toString powermenuType}";
  themeStyles =
    if cfg.theme != null
    then ''@import "${rofiThemes}/colors/${cfg.theme}.rasi"''
    else "TODO: custom theme here";
  # replace the imports with preset theme / wallust
  fixupRofiThemesRasi = rasiPath: additionalStyles: ''
    ${themeStyles}
    ${builtins.replaceStrings ["@import"] ["// @import"] (builtins.readFile rasiPath)}
    window {
      width: ${toString cfg.width}px;
    }
    ${additionalStyles}
  '';
  # NOTE: rofi-power-menu only works for powermenuType = 4!
  rofi-power-menu = pkgs.writeShellApplication {
    name = "rofi-power-menu";
    runtimeInputs = with pkgs; [rofi iynaix.rofi-themes];
    text = builtins.replaceStrings ["@@theme@@"] ["${powermenuDir}/style-${toString powermenuStyle}.rasi"] (builtins.readFile ./rofi-powermenu.sh);
  };
in {
  programs.rofi = {
    enable = true;
    package = pkgs.rofi-wayland;
  };

  home.packages = [rofi-power-menu];

  xdg.configFile = {
    "rofi/rofi-wifi-menu" = lib.mkIf config.iynaix.wifi.enable {
      source = ./rofi-wifi-menu.sh;
    };

    "rofi/config.rasi".text = ''
      @theme "~/.cache/wallust/rofi.rasi"
    '';
  };

  # add blur for rofi shutdown
  wayland.windowManager.hyprland.settings.layerrule =
    lib.mkIf config.wayland.windowManager.hyprland.enable ["blur,rofi"];

  # TODO: wallust for dynamic rofi themes
  # TODO: rofi-wifi-menu
  # TODO: rofi rclip?

  iynaix.wallust.entries = {
    # default launcher
    "rofi.rasi" = {
      enable = config.programs.rofi.enable;
      text = fixupRofiThemesRasi "${rofiThemes}/launchers/type-${toString launcherType}/style-${toString launcherStyle}.rasi" "";
      target = "~/.cache/wallust/rofi.rasi";
    };

    # generic single column rofi menu
    "rofi-menu.rasi" = {
      enable = config.programs.rofi.enable;
      text = fixupRofiThemesRasi "${rofiThemes}/launchers/type-${toString menuType}/style-${toString menuStyle}.rasi" ''
        prompt { enabled: false; }
        textbox-prompt-colon { enabled: false; }
      '';
      target = "~/.cache/wallust/rofi-menu.rasi";
    };

    "rofi-screenshot.rasi" = {
      enable = config.programs.rofi.enable;
      text = fixupRofiThemesRasi "${rofiThemes}/launchers/type-${toString menuType}/style-${toString menuStyle}.rasi" ''
        * { width: 1000; }
        window { height: 625; }
        mainbox {
            children: [listview,message];
        }
        message {
          padding:                     15px;
          border:                      0px solid;
          border-radius:               0px;
          border-color:                @selected;
          background-color:            @background;
          text-color:                  @foreground;
        }
      '';
      target = "~/.cache/wallust/rofi-screenshot.rasi";
    };

    "rofi-shutdown-confirm.rasi" = {
      enable = config.programs.rofi.enable;
      text = fixupRofiThemesRasi "${powermenuDir}/shared/confirm.rasi" "";
      target = "~/.cache/wallust/rofi-shutdown-confirm.rasi";
    };
  };
}
