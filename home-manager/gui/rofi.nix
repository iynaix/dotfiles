{
  config,
  isNixOS,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib)
    mkIf
    mkOption
    optionals
    ;
  inherit (lib.types)
    enum
    int
    nullOr
    package
    ;
  cfg = config.custom.rofi;
  rofiThemes = pkgs.custom.rofi-themes;
  patchRasi =
    name: rasiPath: overrideStyles:
    let
      themeStyles =
        if cfg.theme != null then
          ''@import "${rofiThemes}/colors/${cfg.theme}.rasi"''
        else
          # css
          ''
            *   {
                background:     {{background}}{{ 60 | alpha_hexa }};
                background-alt: {{color0}};
                foreground:     {{foreground}};
                selected:       {{color4}};
                active:         {{color6}};
                urgent:         {{color1}};
            }
          '';
      # patch rasi here
      out = pkgs.runCommand name { } ''
        mkdir $out

        output=$out/${name}

        substitute ${rasiPath} $output \
          --replace-quiet "@import" "// @import" \
          --replace-quiet "" "" \
          --replace-quiet "Iosevka Nerd Font" "DejaVu Sans"

        # prepend
        cat <<EOF | cat - $output > temp && mv temp $output
            ${themeStyles}
        EOF

        # append
        cat <<EOF >> $output
          window {
            width: ${toString cfg.width}px;
          }

          element normal.normal { background-color: transparent; }
          inputbar { background-color: transparent; }
          message { background-color: transparent; }
          textbox { background-color: transparent; }

          ${overrideStyles}
        EOF
      '';
    in
    "${toString out}/${name}";
  launcherPath = "${rofiThemes}/launchers/type-2/style-2.rasi";
  powermenuDir = "${rofiThemes}/powermenu/type-4";
in
{
  options.custom = {
    rofi = {
      theme = mkOption {
        type = nullOr (enum [
          "adapta"
          "arc"
          "black"
          "catppuccin"
          "cyberpunk"
          "dracula"
          "everforest"
          "gruvbox"
          "lovelace"
          "navy"
          "nord"
          "onedark"
          "paper"
          "solarized"
          "tokyonight"
          "yousai"
        ]);
        default = null;
        description = "Rofi launcher theme";
      };
      width = mkOption {
        type = int;
        default = 800;
        description = "Rofi launcher width";
      };
    };

    # allow setting a custom rofi-power-menu package to add the reboot to windows option
    rofi-power-menu = {
      package = mkOption {
        type = package;
        default = pkgs.custom.rofi-power-menu.override {
          reboot-to-windows =
            if (config.custom.mswindows && isNixOS) then pkgs.custom.shell.reboot-to-windows else null;
        };
        description = "Package to use for rofi-wifi-menu";
      };
    };
  };

  config = mkIf (config.custom.wm != "tty") {
    programs.rofi = {
      enable = true;
      package = pkgs.rofi-wayland.override {
        plugins = [ rofiThemes ];
      };
      theme = "${config.xdg.cacheHome}/wallust/rofi.rasi";
    };

    home.packages = [
      # NOTE: rofi-power-menu only works for powermenuType = 4!
      config.custom.rofi-power-menu.package
    ] ++ (optionals config.custom.wifi.enable [ pkgs.custom.rofi-wifi-menu ]);

    # add blur for rofi shutdown
    wayland.windowManager.hyprland.settings = {
      layerrule = [
        "blur,rofi"
        "dimaround,rofi"
        "ignorealpha 0,rofi"
      ];

      # force center rofi on monitor
      windowrule = [
        "float,class:(Rofi)"
        "center,class:(Rofi)"
        "rounding 12,class:(Rofi)"
        "dimaround,class:(Rofi)"
      ];
    };

    programs.niri.settings = {
      # fake dimaround, see:
      # https://github.com/YaLTeR/niri/discussions/1806
      layer-rules = [
        {
          matches = [ { namespace = "^rofi$"; } ];
          shadow = {
            enable = true;
            spread = 1024;
            draw-behind-window = true;
            color = "0000009A";
          };
        }
      ];
    };

    custom.wallust.templates = mkIf config.programs.rofi.enable {
      # default launcher
      "rofi.rasi" = {
        text = patchRasi "rofi.rasi" launcherPath ''
          inputbar { background-color: transparent; }
          element normal.normal { background-color: transparent; }
        '';
        target = "${config.xdg.cacheHome}/wallust/rofi.rasi";
      };

      # generic single column rofi menu
      "rofi-menu.rasi" = {
        text = patchRasi "rofi-menu.rasi" launcherPath ''
          listview { columns: 1; }
          prompt { enabled: false; }
          textbox-prompt-colon { enabled: false; }
        '';
        target = "${config.xdg.cacheHome}/wallust/rofi-menu.rasi";
      };

      "rofi-menu-noinput.rasi" = {
        text = patchRasi "rofi-menu-noinput.rasi" launcherPath ''
          listview { columns: 1; }
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
            /* background-color is set in style overrides */
            text-color:                  @foreground;
          }
        '';
        target = "${config.xdg.cacheHome}/wallust/rofi-menu-noinput.rasi";
      };

      "rofi-power-menu.rasi" =
        let
          columns = if config.custom.mswindows then 6 else 5;
        in
        {
          text = patchRasi "rofi-power-menu.rasi" "${powermenuDir}/style-3.rasi" ''
            * { background-window: @background; } // darken background
            window {
              width: ${toString (columns * 200)}px;
              border-radius: 12px; // no rounded corners as it doesn't interact well with blur on hyprland
            }
            element normal.normal { background-color: var(background-normal); }
            element selected.normal { background-color: @selected; }
            element-text { vertical-align: 0; }
            listview { columns: ${toString columns}; }
          '';
          target = "${config.xdg.cacheHome}/wallust/rofi-power-menu.rasi";
        };

      "rofi-power-menu-confirm.rasi" = {
        text = patchRasi "rofi-power-menu-confirm.rasi" "${powermenuDir}/shared/confirm.rasi" ''
          element { background-color: transparent; }
          element normal.normal { background-color: transparent; }
        '';
        target = "${config.xdg.cacheHome}/wallust/rofi-power-menu-confirm.rasi";
      };
    };
  };
}
