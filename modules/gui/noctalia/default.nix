{ inputs, lib, ... }: {
  perSystem = { pkgs, ... }: {
    packages = {
      # TODO: wrapper for noctalia v5
      noctalia = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs (o: {
        patches = (o.patches or [ ]) ++ [
          ./face-aware-crop.patch
        ];
      });
    };
  };

  flake.modules.nixos.core =
    { pkgs, ... }:
    let
      tomlFormat = pkgs.formats.toml { };
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
    };

  flake.modules.nixos.wm =
    { config, pkgs, ... }:
    let
      tomlFormat = pkgs.formats.toml { };
      inherit (config.custom.constants) isLaptop;
      noctalia-start = pkgs.writeShellApplication {
        name = "noctalia-start";
        runtimeInputs = [
          pkgs.noctalia
          config.custom.programs.dotfiles-rs
        ];
        text = /* sh */ ''
          noctalia &
          sleep 3
          # hide on laptop screens to save space
          ${lib.optionalString isLaptop "noctalia msg bar-hide"}
          wallpaper
        '';
      };
      noctalia-reload = pkgs.writeShellApplication {
        name = "noctalia-reload";
        text = /* sh */ ''
          killall noctalia || true
          # prevent "already running" error
          sleep 0.2
          noctalia &
        '';
      };
    in
    {
      nixpkgs.overlays = [
        (_: _prev: {
          inherit (pkgs.custom) noctalia;
        })
      ];

      environment.systemPackages = [
        pkgs.noctalia # overlay-ed above
        noctalia-reload
      ];

      hj.xdg = {
        config.files = {
          "noctalia/config.toml".source = ./settings.toml;
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
        # start noctalia after the WM is ready
        wm.startup = lib.mkBefore [
          {
            spawn = lib.getExe noctalia-start;
          }
        ];

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

          niri.settings = {
            layer-rules = [
              # use blurred overview for noctalia
              {
                matches = [ { namespace = "^noctalia-backdrop"; } ];
                place-within-backdrop = true;
              }

              # Disable xray on all our surfaces so it looks more realistic.
              # Noctalia publishes blur regions automatically when ext-background-effects is available.
              {
                matches = [ { namespace = "^noctalia-(bar-[^\"]+|notification|dock|panel|attached-panel|osd)$"; } ];
                background-effect = {
                  xray = false;
                  # blur =false;
                };
              }
            ];
          };

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
}
