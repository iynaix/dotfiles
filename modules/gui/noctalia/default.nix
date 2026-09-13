{
  packages =
    {
      inputs,
      lib,
      pkgs,
      ...
    }:
    {
      noctalia = inputs.wrappers.wrappers.noctalia.wrap {
        inherit pkgs;
        package = pkgs.noctalia.overrideAttrs (o: {
          src = pkgs.fetchFromGitHub {
            owner = "noctalia-dev";
            repo = "noctalia";
            rev = "2856ec3b1b384f243770240261a11831de51a923";
            hash = "sha256-n5lAaFSofJDpBrzRks4H9moBNAOAyQ0GMnlYWSQl8uo=";
          };

          # skip tests
          mesonFlags = (o.mesonFlags or [ ]) ++ [ (lib.mesonEnable "tests" false) ];

          patches = (o.patches or [ ]) ++ [
            ./face-aware-crop.patch
          ];
        });
        settings = builtins.fromTOML (builtins.readFile ./noctalia.toml);
      };
    };

  tags = [ "wm" ];

  config =
    {
      config,
      inputs,
      lib,
      pkgs,
      tags,
      ...
    }:
    let
      tomlFormat = pkgs.formats.toml { };

      noctalia-reload = pkgs.writeShellApplication {
        name = "noctalia-reload";
        text = /* sh */ ''
          systemctl restart --user noctalia
        '';
      };
    in
    {
      options.custom = {
        programs.noctalia = {
          inherit (inputs.wrappers.wrappers.noctalia.wrapperOptions) settings;

          user-templates = lib.mkOption {
            inherit (tomlFormat) type;
            default = { };
            description = ''
              TOML config for noctalia user templates, see
              https://docs.noctalia.dev/noctalia/theming/app-theming/?section=user-templates#user-templates
              for available options
            '';
          };
        };
      };

      config = {
        nixpkgs.overlays = [
          (_: _prev: {
            noctalia = pkgs.custom.noctalia.wrap {
              settings = lib.mkMerge [
                config.custom.programs.noctalia.settings
                { theme.templates.user = config.custom.programs.noctalia.user-templates; }
              ];
            };
          })
        ];

        programs.noctalia = {
          enable = true;
          package = pkgs.noctalia; # overlay-ed above
          systemd.enable = true;
        };

        systemd.user.services.noctalia = {
          environment = {
            # fix launcher icons?
            QT_QPA_PLATFORMTHEME = "gtk3";
          };
          serviceConfig = {
            # hide the bar on laptop screens for more space
            ExecStartPost = lib.mkIf (builtins.elem "laptop" tags) "${lib.getExe config.programs.noctalia.package} msg bar-hide";
          };
        };

        environment.systemPackages = [
          noctalia-reload
          pkgs.wlr-randr
        ];

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
              noctalia = /* sh */ ''cat ${config.programs.noctalia.package.configuration.constructFiles.settings.outPath} "${config.hj.xdg.state.directory}/noctalia/settings.toml" | moor --lang toml'';
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
