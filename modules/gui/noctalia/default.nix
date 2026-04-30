{
  inputs,
  lib,
  ...
}:
let
  baseNoctaliaSettings = builtins.fromJSON (builtins.readFile ./settings.json);
in
{
  perSystem =
    { pkgs, ... }:
    {
      packages = {
        noctalia-shell = inputs.wrappers.wrappers.noctalia-shell.wrap (wrapperArgs: {
          inherit pkgs;
          package =
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

          settings =
            [
              # don't expose toggle-speaker
              (
                prev:
                lib.recursiveUpdate prev {
                  bar.widgets.right = map (
                    widget:
                    if widget.id == "Volume" then
                      widget // { middleClickCommand = "pwvucontrol || pavucontrol"; }
                    else
                      widget
                  ) prev.bar.widgets.right;
                }
              )
              # don't set monitorForColors
              (prev: lib.recursiveUpdate prev { colorSchemes.monitorForColors = ""; })
            ]
            |> lib.foldl' (curr: reducer: reducer curr) baseNoctaliaSettings;

          autoCopyConfig = false; # don't copy config on startup
          enableDumpScript = false; # dumps config as nix, not needed

          # for screen recorder plugin
          extraPackages = [ pkgs.gpu-screen-recorder ];

          constructFiles =
            let
              # creates a binary using writeShellApplication suitable for constructFiles from nix-wrapper-modules
              # greatly reducing the boilerplate
              # takes the same arguments as writeShellApplication
              constructFilesShellApplication = args: {
                key = args.name;
                relPath = "bin/${args.name}";
                builder = ''mkdir -p "$(dirname "$2")" && cp "$1" "$2" && chmod +x "$2"'';
                content = (pkgs.writeShellApplication args).text;
              };
              settingsJsonPath = "${wrapperArgs.config.configPlaceholder}/settings.json";
              binaryPath = wrapperArgs.config.wrapperPaths.placeholder;
            in
            {
              noctalia-copy = constructFilesShellApplication {
                name = "noctalia-copy";
                runtimeInputs = with pkgs; [
                  jq
                  wl-clipboard
                ];
                text = /* sh */ ''
                  noctalia-ipc state all | jq -S '.settings' | wl-copy
                '';
              };

              noctalia-diff = constructFilesShellApplication {
                name = "noctalia-diff";
                runtimeInputs = with pkgs; [
                  jq
                  json-diff
                ];
                text = /* sh */ ''
                  json-diff \
                    <(jq -S . "${settingsJsonPath}") \
                    <(noctalia-ipc state all | jq -S '.settings')
                '';
              };

              # wrapped noctalia ipc to automatically kill outdated instances of noctalia-shell and restart
              noctalia-ipc = constructFilesShellApplication {
                name = "noctalia-ipc";
                runtimeInputs = [
                  inputs.noctalia.inputs.noctalia-qs.packages.${pkgs.stdenv.hostPlatform.system}.default
                  pkgs.killall
                  pkgs.jq
                ];
                text = /* sh */ ''
                  RAW_OUTPUT=$(qs list --all --json 2>/dev/null)

                  # invalid json, no instances running, so start noctalia-shell
                  if [[ ! "$RAW_OUTPUT" == "["* ]]; then
                    ${binaryPath}
                    exit
                  fi

                  NOCTALIA_PATH=$(jq -r '.[] | .config_path | sub("/share/noctalia-shell/shell.qml$"; "")' <<<"$RAW_OUTPUT")

                  # using dev version, don't kill the shell
                  if [[ "$NOCTALIA_PATH" =~ "_dirty" ]]; then
                    "$NOCTALIA_PATH/bin/noctalia-shell" ipc call "$@"
                    exit
                  fi

                  # different instance, kill previous instances
                  if [[ ! "$NOCTALIA_PATH" =~ "${toString wrapperArgs.config.package}" ]]; then
                    killall .quickshell-wra || true
                    ${binaryPath}
                    sleep 2
                  fi

                  ${binaryPath} ipc call "$@"
                '';
              };

              noctalia-reload = constructFilesShellApplication {
                name = "noctalia-reload";
                text = /* sh */ ''
                  killall .quickshell-wra || true
                  # prevent "already running" error
                  sleep 0.2
                  noctalia-shell
                '';
              };
            };
        });
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
      noctalia-start = pkgs.writeShellApplication {
        name = "noctalia-start";
        runtimeInputs = [
          pkgs.noctalia-shell
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
          noctalia-shell = pkgs.custom.noctalia-shell.wrap {
            # apply reducers to default settings
            settings = lib.mkForce (
              config.custom.programs.noctalia.settingsReducers
              |> lib.foldl' (curr: reducer: reducer curr) baseNoctaliaSettings
            );
          };
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
                projectDirs = [
                  config.custom.constants.projects
                  "/tmp"
                ];
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
        pkgs.noctalia-shell # overlay-ed above
        noctalia-start
      ];

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
