{
  packages =
    { pkgs, ... }:
    {
      # TODO: wrapper for noctalia v5
      noctalia = pkgs.noctalia.overrideAttrs (o: {
        patches = (o.patches or [ ]) ++ [
          ./face-aware-crop.patch
        ];
      });
    };

  tags = [ "wm" ];

  config =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      tomlFormat = pkgs.formats.toml { };

      # noctalia-start = pkgs.writeShellApplication {
      #   name = "noctalia-start";
      #   runtimeInputs = [
      #     pkgs.noctalia
      #     config.custom.programs.dotfiles-rs
      #   ];
      #   text = /* sh */ ''
      #     noctalia &
      #     sleep 3
      #     # hide on laptop screens to save space
      #     ${lib.optionalString (builtins.elem "laptop" tags) "noctalia msg bar-hide"}
      #     wallpaper
      #   '';
      # };

      noctalia-reload = pkgs.writeShellApplication {
        name = "noctalia-reload";
        text = /* sh */ ''
          systemctl restart noctalia
        '';
      };
    in
    {
      options.custom = {
        programs.noctalia = {
          colors = lib.mkOption {
            inherit (tomlFormat) type;
            default = { };
            description = ''
              TOML config for noctalia, similar to https://iniox.github.io/#matugen/configuration for
              available options
            '';
          };

          settings = lib.mkOption {
            inherit (tomlFormat) type;
            default = { };
            example = lib.literalExpression ''
              control_center.shortcuts = [
                  { type = "wifi"; }
                  { type = "bluetooth"; }
                  { type = "caffeine"; }
                  { type = "notification"; }
              ];
            '';
            description = ''
              Configuration for noctalia, this will be added as a separate `host.toml` file
            '';
          };
        };
      };

      config = {
        nixpkgs.overlays = [
          (_: _prev: {
            inherit (pkgs.custom) noctalia;
          })
        ];

        programs.noctalia = {
          enable = true;
          package = pkgs.noctalia; # overlay-ed above
          systemd.enable = true;
        };

        environment.systemPackages = [
          noctalia-reload
        ];

        hj.xdg = {
          config.files = {
            "noctalia/config.toml".source = ./noctalia.toml;
            "noctalia/host.toml" = {
              generator = tomlFormat.generate "host.toml";
              value = config.custom.programs.noctalia.settings;
            };
            "noctalia/user-templates.toml" = {
              generator = tomlFormat.generate "user-template.toml";
              value = {
                theme.templates.user = config.custom.programs.noctalia.colors;
              };
            };
          };
        };

        custom = {
          programs = {
            hyprland.settings = /* lua */ ''
              hl.layer_rule({
                name = "noctalia",
                match = {
                  namespace = "^noctalia-(bar-.+|notification|dock|panel|attached-panel|osd)$",
                },
                no_anim = true,
                ignore_alpha = 0.5,
                blur = true,
                blur_popups = true,
              })
            '';

            umbriel.settings.layer_rule = [
              {
                match.namespace = "^noctalia-(bar-[^\"]+|notification|dock|panel|attached-panel|osd)$";
                blur = true;
                blur_ignore_alpha = 0.5;
                blur_optimized = false;
              }
            ];

            # base control center shortcuts across all hosts
            noctalia.settings = {
              control_center.shortcuts = [
                { type = "caffeine"; } # idle inhibit
                { type = "notification"; } # DND
              ];
            };

            print-config = {
              noctalia = /* sh */ ''cat ${config.hj.xdg.config.directory}/noctalia/* "${config.hj.xdg.state.directory}/noctalia/settings.toml" | moor --lang toml'';
            };
          };

          persist = {
            home = {
              directories = [
                ".local/state/noctalia"
              ];
            };
          };
        };
      };
    };
}
