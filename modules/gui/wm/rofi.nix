{
  flake.nixosModules.wm =
    {
      config,
      pkgs,
      ...
    }:
    let
      rofiThemesPkg = pkgs.custom.rofi-themes;
      patchRasi =
        name: rasiPath: overrideStyles:
        let
          themeStyles = /* css */ ''
            *   {
                background:     {{colors.surface.default.hex | to_color | set_alpha: 0.6 }};
                background-alt: {{colors.surface_dim.default.hex}};
                foreground:     {{colors.on_surface.default.hex}};
                selected:       {{colors.primary.default.hex}};
                active:         {{colors.on_primary.default.hex}};
                urgent:         {{colors.error.default.hex}};
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
          @theme "${config.hj.xdg.config.directory}/rofi/rofi.rasi"
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
            "match:namespace rofi, blur on, dim_around on, ignore_alpha 0"
          ];

          # force center rofi on monitor
          windowrule = [
            "match:class Rofi, float on, center on, rounding 12, dim_around on"
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

        matugen.settings.templates = {
          # default launcher
          "rofi.rasi" = {
            input_path = patchRasi "rofi.rasi" launcherPath ''
              inputbar { background-color: transparent; }
              element normal.normal { background-color: transparent; }
            '';
            output_path = "${config.hj.xdg.config.directory}/rofi/rofi.rasi";
          };

          # generic single column rofi menu
          "rofi-menu.rasi" = {
            input_path = patchRasi "rofi-menu.rasi" launcherPath ''
              listview { columns: 1; }
              prompt { enabled: false; }
              textbox-prompt-colon { enabled: false; }
            '';
            output_path = "${config.hj.xdg.config.directory}/rofi/rofi-menu.rasi";
          };

          "rofi-menu-noinput.rasi" = {
            input_path = patchRasi "rofi-menu-noinput.rasi" launcherPath ''
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
            output_path = "${config.hj.xdg.config.directory}/rofi/rofi-menu-noinput.rasi";
          };
        };
      };
    };
}
