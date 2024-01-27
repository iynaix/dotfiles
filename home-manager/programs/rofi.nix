{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.custom.rofi;
  rofiThemes = "${pkgs.custom.rofi-themes}/files";
  launcherType = 2;
  launcherStyle = 2;
  powermenuType = 4;
  powermenuStyle = 3;
  powermenuDir = "${rofiThemes}/powermenu/type-${toString powermenuType}";
  themeStyles =
    if cfg.theme != null
    then ''@import "${rofiThemes}/colors/${cfg.theme}.rasi"''
    else ''
      * {
          background:     {background};
          background-alt: {color0};
          foreground:     {foreground};
          selected:       {color4};
          active:         {color6};
          urgent:         {color1};
      }
    '';

  # replace the imports with preset theme / wallust
  fixupRofiThemesRasi = rasiPath: additionalStyles: ''
    ${themeStyles}
    ${lib.replaceStrings ["@import"] ["// @import"] (builtins.readFile rasiPath)}
    window {
      width: ${toString cfg.width}px;
    }
    ${additionalStyles}
  '';
  # NOTE: rofi-power-menu only works for powermenuType = 4!
  rofi-power-menu = pkgs.writeShellApplication {
    name = "rofi-power-menu";
    runtimeInputs = with pkgs; [rofi custom.rofi-themes];
    text = lib.replaceStrings ["@theme@"] [
      (builtins.toFile "rofi-power-menu.rasi" ((builtins.readFile "${powermenuDir}/style-${toString powermenuStyle}.rasi")
        + ''
          * { background-window: black/60%; } // darken background
          window { border-radius: 12px; } // no rounded corners as it doesn't interact well with blur on hyprland
        ''))
    ] (builtins.readFile ./rofi-power-menu.sh);
  };
in {
  programs.rofi = {
    enable = true;
    package = pkgs.rofi-wayland;
  };

  home.packages = [rofi-power-menu];

  xdg.configFile = {
    "rofi/rofi-wifi-menu" = lib.mkIf config.custom.wifi.enable {
      # https://github.com/ericmurphyxyz/rofi-wifi-menu/blob/master/rofi-wifi-menu.sh
      source = ./rofi-wifi-menu.sh;
    };

    "rofi/config.rasi".text = ''
      @theme "${config.xdg.cacheHome}/wallust/rofi.rasi"
    '';
  };

  # add blur for rofi shutdown
  wayland.windowManager.hyprland.settings = {
    layerrule = [
      "blur,rofi"
      "ignorealpha 0,rofi"
    ];

    # force center rofi on monitor
    windowrulev2 = [
      "float,class:(Rofi)"
      "center,class:(Rofi)"
      "rounding 12,class:(Rofi)"
    ];
  };

  custom.wallust.entries = {
    # default launcher
    "rofi.rasi" = {
      inherit (config.programs.rofi) enable;
      text = fixupRofiThemesRasi "${rofiThemes}/launchers/type-${toString launcherType}/style-${toString launcherStyle}.rasi" "";
      target = "${config.xdg.cacheHome}/wallust/rofi.rasi";
    };

    # generic single column rofi menu
    "rofi-menu.rasi" = {
      inherit (config.programs.rofi) enable;
      text = fixupRofiThemesRasi "${rofiThemes}/launchers/type-${toString launcherType}/style-${toString launcherStyle}.rasi" ''
        listview {
          columns: 1;
          lines: 6;
        }
        prompt { enabled: false; }
        textbox-prompt-colon { enabled: false; }
      '';
      target = "${config.xdg.cacheHome}/wallust/rofi-menu.rasi";
    };

    "rofi-screenshot.rasi" = {
      inherit (config.programs.rofi) enable;
      text = fixupRofiThemesRasi "${rofiThemes}/launchers/type-${toString launcherType}/style-${toString launcherStyle}.rasi" ''
        listview {
          columns: 1;
          lines: 6;
        }
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
      target = "${config.xdg.cacheHome}/wallust/rofi-screenshot.rasi";
    };

    "rofi-power-menu-confirm.rasi" = {
      inherit (config.programs.rofi) enable;
      text = fixupRofiThemesRasi "${powermenuDir}/shared/confirm.rasi" "";
      target = "${config.xdg.cacheHome}/wallust/rofi-power-menu-confirm.rasi";
    };
  };
}
