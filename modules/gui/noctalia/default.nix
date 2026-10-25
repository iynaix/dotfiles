{
  packages =
    {
      inputs,
      lib,
      pkgs,
      ...
    }:
    {
      noctalia = inputs.wrappers.wrappers.noctalia.wrap (
        { config, ... }: {
          inherit pkgs;
          package = pkgs.noctalia.overrideAttrs (o: {
            # skip building tests
            mesonFlags = (o.mesonFlags or [ ]) ++ [ (lib.mesonEnable "tests" false) ];

            patches = (o.patches or [ ]) ++ [
              ./face-aware-crop.patch
              # prevent warning about ~/.config/umbriel/config.toml not existing
              ./umbriel-template-no-apply.patch
            ];

            nativeBuildInputs = o.nativeBuildInputs ++ [ pkgs.wrapGAppsHook3 ];

            buildInputs = o.buildInputs ++ [
              pkgs.dconf
              pkgs.gsettings-desktop-schemas
            ];
          });
          settings = fromTOML (builtins.readFile ./noctalia.toml);

          drv.installPhase = ''
            runHook preInstall
            ${lib.getExe config.package} config validate "${config.constructFiles.settings.path}"
            runHook postInstall
          '';
        }
      );
    };

  tags = [ "wm" ];

  config =
    {
      config,
      inputs,
      lib,
      pkgs,
      tags,
      user,
      ...
    }:
    {
      options.custom = {
        programs.noctalia = {
          inherit (inputs.wrappers.wrappers.noctalia.wrapperOptions) settings;

          minibar = lib.mkEnableOption "Alternate centralized minibar rice";
        };
      };

      config = {
        programs.noctalia = {
          enable = true;
          package = pkgs.custom.noctalia.wrap {
            settings = lib.mkMerge [
              config.custom.programs.noctalia.settings
              { theme.templates.user = config.custom.programs.noctalia.user-templates; }
            ];
          };
          systemd.enable = true;
        };

        systemd.user.services.noctalia = {
          serviceConfig = {
            # hide the bar on laptop screens for more space
            ExecStartPost =
              let
                noctalia-post-init = pkgs.writeShellApplication {
                  name = "noctalia-post-init";
                  runtimeInputs = [
                    config.programs.noctalia.package
                    pkgs.coreutils
                  ];
                  text = ''
                    while ! noctalia msg status >/dev/null 2>&1; do
                    ${lib.getExe' pkgs.coreutils "sleep"} 0.5
                    done

                    noctalia msg bar-hide
                  '';
                };
              in
              lib.mkIf (builtins.elem "laptop" tags) (lib.getExe noctalia-post-init);
          };
        };

        environment.systemPackages = [
          pkgs.wlr-randr
        ];

        custom = {
          programs = {
            umbriel.settings.layer_rule = [
              {
                match.namespace = "^noctalia-(bar-[^\"]+|notification|dock|panel|attached-panel|osd)$";
                blur = true;
                blur_ignore_alpha = 0.5;
                blur_optimized = false;
              }
            ];

            noctalia.settings = {
              # base control center shortcuts across all hosts
              control_center.shortcuts = [
                { type = "caffeine"; } # idle inhibit
                { type = "notification"; } # DND
              ];
            }
            # creating centralized pill shaped bar
            // (lib.optionalAttrs config.custom.programs.noctalia.minibar {
              shell.panel = {
                control_center_placement = "floating";
                control_center_position = "top_center";
              };

              bar.default = {
                concave_edge_corners = false;
                radius_top_left = 0;
                radius_top_right = 0;
                radius_bottom_left = 30;
                radius_bottom_right = 30;
                monitor =
                  config.custom.hardware.monitors
                  |> map (
                    d:
                    let
                      target_width = 600;
                      normalized_width = builtins.div (if d.isVertical then d.height else d.width) d.scale;
                    in
                    {
                      inherit (d) name;
                      value = {
                        start = [
                          "control-center"
                          "workspaces"
                        ];
                        center = [ ];
                        margin_ends = builtins.div (normalized_width - target_width) 2;
                      };
                    }
                  )
                  |> lib.listToAttrs;
              };
            });

            print-config = {
              noctalia = /* sh */ ''cat ${config.programs.noctalia.package.configuration.constructFiles.settings.outPath} "/home/${user}/.local/state/noctalia/settings.toml" | moor --lang toml'';
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
