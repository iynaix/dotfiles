{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.custom.rofi;
  rofiThemes = pkgs.custom.rofi-themes;
  patchRasi =
    name: rasiPath: overrideStyles:
    let
      themeStyles =
        if cfg.theme != null then
          ''@import "${rofiThemes}/colors/${cfg.theme}.rasi"''
        else
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
  options.custom = with lib; {
    rofi = {
      theme = mkOption {
        type = types.nullOr (
          types.enum [
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
          ]
        );
        default = null;
        description = "Rofi launcher theme";
      };
      width = mkOption {
        type = types.int;
        default = 800;
        description = "Rofi launcher width";
      };
    };
  };

  config = lib.mkIf (!config.custom.headless) {
    programs.rofi = {
      enable = true;
      package = pkgs.rofi-wayland.override {
        plugins = [ rofiThemes ];
      };
      extraConfig = {
        show-icons = true;
        kb-remove-char-back = "BackSpace";
        kb-remove-word-back = "Control+BackSpace";
        kb-accept-entry = "Control+m,Return,KP_Enter";
        kb-mode-next = "Control+Alt+l";
        kb-mode-previous = "Control+Alt+h";
        kb-row-up = "Control+k,Up";
        kb-row-down = "Control+j,Down";
        kb-row-left = "Control+h";
        kb-row-right = "Control+l";
        kb-mode-complete = "Control+Shift+L";
        kb-delete-entry = "Control+semicolon";
        kb-remove-char-forward = "";
        kb-remove-to-sol = "";
        kb-remove-to-eol = "";
      };
      theme = "${config.xdg.cacheHome}/wallust/rofi.rasi";
    };

    xdg.dataFile."rofi/themes/preview.rasi".text = ''
      @theme "custom"
      icon-current-entry {
        enabled: true;
        size: 50%;
        dynamic: true;
        padding: 10px;
        background-color: inherit;
      }
      listview-split {
        background-color: transparent;
        border-radius: 0px;
        cycle: true;
        dynamic : true;
        orientation: horizontal;
        border: 0px solid;
        children: [listview,icon-current-entry];
      }
      listview {
        lines: 10;
      }
      mainbox {
        children: [inputbar,listview-split];
      }
      @media (enabled: env(EPUB, false)) {
        icon-current-entry {
          size: 35%;
        }
      }
    '';

    home.packages = [
      pkgs.custom.rofi-epub-menu
      pkgs.custom.rofi-pdf-menu
      # NOTE: rofi-power-menu only works for powermenuType = 4!
      pkgs.custom.rofi-power-menu
    ] ++ (lib.optionals config.custom.wifi.enable [ pkgs.custom.rofi-wifi-menu ]);

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

    custom.wallust.templates = lib.mkIf config.programs.rofi.enable {
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

      "rofi-power-menu.rasi" = {
        text = patchRasi "rofi-power-menu.rasi" "${powermenuDir}/style-3.rasi" ''
          * { background-window: @background; } // darken background
          window {
            width: 1000px;
            border-radius: 12px; // no rounded corners as it doesn't interact well with blur on hyprland
          }
          element normal.normal { background-color: var(background-normal); }
          element selected.normal { background-color: @selected; }
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
