{
  packages =
    { inputs, pkgs, ... }:
    {
      kitty = inputs.wrappers.wrappers.kitty.wrap {
        inherit pkgs;
        settings = {
          enable_audio_bell = false;
          copy_on_select = "clipboard";
          scrollback_lines = 10000;
          update_check_interval = 0;
          window_padding_width = 12;
          tab_bar_edge = "top";
          background_opacity = 0.90;
          confirm_os_window_close = 0;
        };
      };
    };

  tags = [ "gui" ];

  config =
    {
      config,
      inputs,
      lib,
      pkgs,
      ...
    }:
    {
      options.custom = {
        # terminal options
        programs.terminal = {
          package = lib.mkOption {
            type = lib.types.package;
            default = pkgs.ghostty;
            description = "Package to use for the terminal";
          };

          app-id = lib.mkOption {
            type = lib.types.str;
            description = "app-id (wm class) for the terminal";
          };

          desktop = lib.mkOption {
            type = lib.types.str;
            default = "${config.custom.programs.terminal.package.pname}.desktop";
            description = "Name of desktop file for the terminal";
          };
        };

        programs.kitty = {
          # use the option from the kitty wrapper module
          inherit (inputs.wrappers.wrappers.kitty.wrapperOptions) settings;
        };
      };

      config = {
        nixpkgs.overlays = [
          (_: _prev: {
            kitty = pkgs.custom.kitty.wrap {
              themeFile = "tokyo_night_night";
              font = {
                name = config.custom.fonts.monospace;
                size = 10;
              };

              settings = config.custom.programs.kitty.settings;
              # enable ligatures
              extraConfig = ''
                font_features JetBrainsMonoNF-Regular +zero
                font_features JetBrainsMonoNF-Bold +zero
                font_features JetBrainsMonoNF-Italic +zero
                font_features JetBrainsMonoNF-BoldItalic +zero

                include ${config.hj.xdg.config.directory}/kitty/kitty.conf
              '';
            };
          })
        ];

        environment = {
          systemPackages = [
            pkgs.kitty # overlay-ed above
          ];

          shellAliases = {
            ssh = "kitten ssh --kitten=color_scheme=Dracula";
          };
        };

        custom.programs = {
          terminal = {
            app-id = "kitty";
            desktop = "kitty.desktop";
          };

          kitty.settings = {
            bold_font = "JetBrainsMono Nerd Font Bold";
            italic_font = "JetBrainsMono Nerd Font Italic";
            bold_italic_font = "JetBrainsMono Nerd Font Bold Italic";
          };

          print-config = {
            kitty = /* sh */ ''
              cat "${pkgs.kitty.configuration.constructFiles.kittyConfig.outPath}" \
                  "${config.hj.xdg.config.directory}/kitty/kitty.conf" \
                  "${config.hj.xdg.config.directory}/kitty/themes/noctalia.conf" | \
                  moor --lang ini'';
          };

          niri.settings.window-rules = [
            {
              matches = [ { app-id = "^kitty"; } ];

              background-effect = {
                blur = true;
              };
            }
          ];
        };
      };
    };
}
