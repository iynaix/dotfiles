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

          # TODO: REMOVE ME!!!
          settingsReducers = lib.mkOption {
            type = lib.types.listOf (
              lib.mkOptionType {
                name = "noctalia-settings-reducer";
                check = lib.isFunction;
              }
            );
            default = [ ];
            description = "Reducers that will be applied to a copy of desktop's settings.json";
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
          "noctalia/settings.toml".source = ./settings.toml;
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
