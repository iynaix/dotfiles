{
  inputs,
  lib,
  ...
}:
{
  perSystem =
    { pkgs, ... }:
    let
      drv =
        {
          lib,
          noctalia-shell,
          writeShellApplication,
          killall,
          jq,
        }:
        # wrapped noctalia ipc to automatically kill outdated instances of noctalia-shell and restart
        writeShellApplication {
          name = "noctalia-ipc";
          runtimeInputs = [
            inputs.noctalia.inputs.noctalia-qs.packages.${pkgs.stdenv.hostPlatform.system}.default
            killall
            jq
          ];
          text = /* sh */ ''
            RAW_OUTPUT=$(qs list --all --json 2>/dev/null)

            # invalid json, no instances running, so start noctalia-shell
            if [[ ! "$RAW_OUTPUT" == "["* ]]; then
              ${lib.getExe noctalia-shell}
              exit
            fi

            NOCTALIA_PATH=$(qs list --all --json | jq -r '.[] | .config_path | sub("/share/noctalia-shell/shell.qml$"; "")')

            # using dev version, don't kill the shell
            if [[ "$NOCTALIA_PATH" =~ "_dirty" ]]; then
              "$NOCTALIA_PATH/bin/noctalia-shell" ipc call "$@"
              exit
            fi

            # different instance, kill previous instances
            if [[ ! "$NOCTALIA_PATH" =~ ${noctalia-shell} ]]; then
              killall .quickshell-wra || true
              ${lib.getExe noctalia-shell}
              sleep 2
            fi

            ${lib.getExe noctalia-shell} ipc call "$@"
          '';
        };
    in
    {
      packages = rec {
        noctalia-shell' =
          (inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default.override {
            calendarSupport = true;
          }).overrideAttrs
            (o: {
              patches = [
                ./face-aware-crop.patch
                # write plugin settings to ~/.cache/noctalia instead so git doesn't fail to clone to a non-empty directory
                ./plugin-settings-location.patch
                # battery and volume widgets that use the primary color instead of white
                ./mprimary-battery.patch
                # remove transparency from zathura template
                ./zathura-transparency.patch
              ];

              postPatch = /* sh */ ''
                # don't want to add python3 to the global path
                substituteInPlace Services/Theming/TemplateProcessor.qml \
                  --replace-fail "python3" "${lib.getExe pkgs.python3}"

                # show location on weather card in clock panel
                substituteInPlace Modules/Panels/Clock/ClockPanel.qml \
                  --replace-fail "showLocation: false" "showLocation: true"
              '';

              # fix missing app icons:
              # https://docs.noctalia.dev/getting-started/faq/#configuration
              preFixup = (o.preFixup or "") + /* sh */ ''
                qtWrapperArgs+=(
                  --set QT_QPA_PLATFORMTHEME gtk3
                )
              '';
            });
        noctalia-ipc = pkgs.callPackage drv { noctalia-shell = noctalia-shell'; };
        noctalia-copy = pkgs.writeShellApplication {
          name = "noctalia-copy";
          runtimeInputs = with pkgs; [
            jq
            wl-clipboard
          ];
          text = /* sh */ ''
            noctalia-shell ipc call state all | jq -S '.settings' | wl-copy
          '';
        };
        noctalia-diff = pkgs.writeShellApplication {
          name = "noctalia-diff";
          runtimeInputs = with pkgs; [
            jq
            json-diff
          ];
          text = /* sh */ ''
            json-diff \
              <(jq -S . "''${XDG_CONFIG_HOME:-$HOME/.config}/noctalia/settings.json") \
              <(noctalia-shell ipc call state all | jq -S '.settings')
          '';
        };
      };
    };

  flake.modules.nixos.core = {
    options.custom = {
      programs.noctalia = {
        # reducer functions are used instead of plain attrsets, as attrsets cannot be merged together to override
        # lists at arbitrary indexes
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
      inherit (config.custom.constants) isLaptop;
      # settings.json is the desktop copy of gui-settings.json without any modifications
      defaultSettings = builtins.fromJSON (builtins.readFile ./settings.json);
      noctalia-reload = pkgs.writeShellApplication {
        name = "noctalia-reload";
        text = /* sh */ ''
          killall .quickshell-wra || true
          # prevent "already running" error
          sleep 0.2
          noctalia-shell
        '';
      };
      noctalia-start = pkgs.writeShellApplication {
        name = "noctalia-start";
        runtimeInputs = [
          pkgs.noctalia-shell
          pkgs.custom.noctalia-ipc # needed for wallpaper
          config.custom.programs.dotfiles-rs
        ];
        text = /* sh */ ''
          noctalia-shell &
          sleep 3
          # hide on laptop screens to save space
          ${lib.optionalString isLaptop "noctalia-shell ipc call bar hide"}
          wallpaper
        '';
      };
    in
    {
      nixpkgs.overlays = [
        (_: _prev: {
          noctalia-shell = pkgs.custom.noctalia-shell';
        })
      ];

      hj.xdg =
        let
          official = "https://github.com/noctalia-dev/noctalia-plugins";
          my-plugins = "https://github.com/iynaix/noctalia-plugins-iynaix";
          my-plugins-hash = my-plugins |> builtins.hashString "sha256" |> builtins.substring 0 6;
        in
        {
          config.files = {
            "noctalia/settings.json" = {
              generator = lib.strings.toJSON;
              # create settings by applying reducers
              value =
                config.custom.programs.noctalia.settingsReducers
                |> lib.foldl' (curr: reducer: reducer curr) defaultSettings;
            };
            "noctalia/plugins.json" = {
              generator = lib.strings.toJSON;
              value = {
                sources = [
                  {
                    enabled = true;
                    name = "Official Noctalia Plugins";
                    url = official;
                  }
                  {
                    enabled = true;
                    name = "Iynaix's Noctalia Plugins";
                    url = my-plugins;
                  }
                ];
                states = {
                  # official plugins
                  kaomoji-provider = {
                    enabled = true;
                    sourceUrl = official;
                  };
                  screen-recorder = {
                    enabled = true;
                    sourceUrl = official;
                  };
                  timer = {
                    enabled = true;
                    sourceUrl = official;
                  };
                  polkit-agent = {
                    enabled = true;
                    sourceUrl = official;
                  };
                  # third party plugins
                  "${my-plugins-hash}:projects-provider" = {
                    enabled = true;
                    sourceUrl = my-plugins;
                  };
                };
                version = 2;
              };
            };
            "noctalia/plugin_settings/${my-plugins-hash}:projects-provider-settings.json" = {
              generator = lib.strings.toJSON;
              value = {
                projectDir = config.custom.constants.projects;
                openCommand = "codium %s";
              };
            };
          };
        };

      custom = {
        # start noctalia after the WM is ready
        startup = lib.mkBefore [
          {
            spawn = [ (lib.getExe noctalia-start) ];
          }
        ];

        programs = {
          # setup blur for hyprland
          hyprland.settings = {
            windowrule = [
              "match:class dev.noctalia.noctalia-qs, rounding 20"
            ];

            layerrule = [
              "match:namespace noctalia-background-.*$, ignore_alpha 0.5, blur on"
            ];
          };

          niri.settings = {
            # bar blur
            layer-rules = [
              {
                matches = [ { namespace = "^noctalia-background-.*$"; } ];
                background-effect = {
                  blur = true;
                };
              }
            ];

            # settings window blur
            window-rules = [
              {
                matches = [ { app-id = "^dev.noctalia.noctalia-qs$"; } ];

                geometry-corner-radius = 20;
                background-effect = {
                  blur = true;
                };
              }
            ];
          };

          print-config = {
            noctalia = /* sh */ ''noctalia-shell ipc call state all | ${lib.getExe pkgs.jq} -S ".settings" | moor'';
          };
        };
      };

      environment.systemPackages = [
        pkgs.noctalia-shell
        pkgs.gpu-screen-recorder # screen recorder plugin
        noctalia-reload
        noctalia-start
      ]
      ++ (with pkgs.custom; [
        noctalia-copy
        noctalia-ipc
        noctalia-diff
      ]);

      custom.persist = {
        home = {
          directories = [
            ".config/noctalia"
          ];

          # wallpapers.json contains the last set wallpaper
          cache.directories = [
            ".cache/noctalia"
          ];
        };
      };
    };
}
