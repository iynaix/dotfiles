{
  flake.nixosModules.wm =
    {
      config,
      pkgs,
      ...
    }:
    let
      rofiTheme = null;
      rofiThemesPkg = pkgs.custom.rofi-themes;
      patchRasi =
        name: rasiPath: overrideStyles:
        let
          themeStyles =
            if rofiTheme != null then
              ''@import "${rofiThemesPkg}/colors/${rofiTheme}.rasi"''
            else
              /* css */ ''
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
                width: 800px;
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
      launcherPath = "${rofiThemesPkg}/launchers/type-2/style-2.rasi";
    in
    {
      nixpkgs.overlays = [
        (_: prev: {
          # TODO: bake theme in instead of using ~/.config/rofi/config.rasi?
          rofi = prev.rofi.override {
            plugins = [ rofiThemesPkg ];
          };
        })
      ];

      hj.xdg.config.files."rofi/config.rasi" = {
        text = ''
          configuration {
            location: 0;
            xoffset: 0;
            yoffset: 0;
          }
          @theme "${config.hj.xdg.cache.directory}/wallust/rofi.rasi"
        '';
        type = "copy";
      };

      environment.systemPackages = [
        pkgs.rofi
      ];

      # add blur for rofi shutdown
      custom.programs = {
        hyprland.settings = {
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

        # fake dimaround, see:
        # https://github.com/YaLTeR/niri/discussions/1806
        niri.settings.config = /* kdl */ ''
          layer-rule {
              match namespace="^rofi$"
              shadow {
                  on
                  // overwritten by wallpaper script later
                  spread 1024
                  draw-behind-window true
                  color "0000009A"
              }
          }
        '';

        wallust.templates = {
          # default launcher
          "rofi.rasi" = {
            text = patchRasi "rofi.rasi" launcherPath ''
              inputbar { background-color: transparent; }
              element normal.normal { background-color: transparent; }
            '';
            target = "${config.hj.xdg.cache.directory}/wallust/rofi.rasi";
          };

          # generic single column rofi menu
          "rofi-menu.rasi" = {
            text = patchRasi "rofi-menu.rasi" launcherPath ''
              listview { columns: 1; }
              prompt { enabled: false; }
              textbox-prompt-colon { enabled: false; }
            '';
            target = "${config.hj.xdg.cache.directory}/wallust/rofi-menu.rasi";
          };
        };
      };
    };
}
