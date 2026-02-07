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
            killall
            jq
          ];
          text = /* sh */ ''
            RAW_OUTPUT=$(noctalia-shell list --all --json 2>/dev/null)

            # invalid json, no instances running, so start noctalia-shell
            if [[ ! "$RAW_OUTPUT" == "["* ]]; then
              systemctl --user restart noctalia-shell
              exit
            fi

            NOCTALIA_PATH=$(noctalia-shell list --all --json | jq -r '.[] | .config_path | sub("/share/noctalia-shell/shell.qml$"; "")')

            # using dev version, don't kill the shell
            if [[ "$NOCTALIA_PATH" =~ "_dirty" ]]; then
              "$NOCTALIA_PATH/bin/noctalia-shell" ipc call "$@"
              exit
            fi

            # different instance, kill previous instances
            if [[ ! "$NOCTALIA_PATH" =~ ${noctalia-shell} ]]; then
              killall .quickshell-wrapper
              systemctl --user restart noctalia-shell
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
            {
              patches = [
                ./face-aware-crop.patch
                # write plugin settings to ~/.cache/noctalia instead so git doesn't fail to clone to a non-empty directory
                ./plugin-settings-location.patch
                # battery and volume widgets that use the primary color instead of white
                # ./mprimary-bar-widgets.patch
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
            };
        noctalia-ipc = pkgs.callPackage drv { noctalia-shell = noctalia-shell'; };
        noctalia-diff = pkgs.writeShellApplication {
          name = "noctalia-diff";
          runtimeInputs = with pkgs; [
            jq
            colordiff
          ];
          text = /* sh */ ''
            diff -u \
              <(jq -S . "''${XDG_CONFIG_HOME:-$HOME/.config}/noctalia/settings.json") \
              <(noctalia-shell ipc call state all | jq -S '.settings') \
              | colordiff --nobanner
          '';
        };
      };
    };

  flake.nixosModules.core = {
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
          description = "Reducers that will be applied to a copy of desktop's gui-settings.json";
        };
      };
    };
  };

  flake.nixosModules.wm =
    { config, pkgs, ... }:
    let
      inherit (config.custom.constants) isLaptop;
      # settings.json is the desktop copy of gui-settings.json without any modifications
      defaultSettings = builtins.fromJSON (builtins.readFile ./settings.json);
      noctalia-shell-reload = pkgs.writeShellApplication {
        name = "noctalia-shell-reload";
        text = /* sh */ ''
          systemctl --user restart noctalia-shell
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
                  # third party plugins
                  "${my-plugins-hash}:projects-provider" = {
                    enabled = true;
                    sourceUrl = my-plugins;
                  };
                };
                version = 2;
              };
            };
          };
          cache.files = {
            "noctalia/plugins/${my-plugins-hash}:projects-provider-settings.json" = {
              generator = lib.strings.toJSON;
              value = {
                projectDir = "~/projects";
                openCommand = "codium %s";
              };
            };
          };
        };

      # custom noctalia service that starts after the WM is ready
      # don't use flake's systemd service, it's very buggy :(
      systemd.user.services = {
        noctalia-shell = {
          description = "Noctalia Shell - Wayland desktop shell";
          documentation = [ "https://docs.noctalia.dev/docs" ];
          partOf = [ "graphical-session.target" ];
          # this shit doesn't work because nixos doesn't properly restart user services
          # https://github.com/NixOS/nixpkgs/issues/246611#issuecomment-3342453760
          restartTriggers = [ pkgs.noctalia-shell ];

          # fix runtime deps when starting noctalia-shell from systemd
          # https://github.com/noctalia-dev/noctalia-shell/pull/418
          environment = {
            PATH = lib.mkForce "/run/wrappers/bin:/etc/profiles/per-user/%u/bin:/nix/var/nix/profiles/default/bin:/run/current-system/sw/bin";
            # fix missing app icons:
            # https://docs.noctalia.dev/getting-started/faq/#configuration
            QT_QPA_PLATFORMTHEME = "gtk3";
          };

          serviceConfig = {
            ExecStart = lib.getExe pkgs.noctalia-shell;
            Restart = "on-failure";
          };
        };

        # run wallpaper after noctalia-shell starts
        wallpaper = {
          wantedBy = [ "noctalia-shell.service" ];

          unitConfig = {
            Description = "Set the wallpapers";
            After = [ "noctalia-shell.service" ];
          };

          serviceConfig = {
            Type = "oneshot";
            ExecStartPre = "${lib.getExe' pkgs.coreutils "sleep"} 3";
            ExecStart = lib.getExe (
              pkgs.writeShellApplication {
                name = "wallpaper-startup";
                runtimeInputs = [
                  pkgs.noctalia-shell
                  pkgs.custom.noctalia-ipc # needed for wallpaper
                  config.custom.programs.dotfiles-rs
                ];
                text = ''
                  # hide on laptop screens to save space
                  ${lib.optionalString isLaptop "noctalia-shell ipc call bar hide"}
                  wallpaper
                '';
              }
            );
            # ensures systemd considers it "active" even after the script finishes
            # this prevents it from restarting again when noctalia-shell restarts after boot
            RemainAfterExit = "yes";
          };
        };
      };

      environment.systemPackages = [
        pkgs.noctalia-shell
        pkgs.gpu-screen-recorder # screen recorder plugin
        noctalia-shell-reload
      ]
      ++ (with pkgs.custom; [
        noctalia-ipc
        noctalia-diff
      ]);

      # start after WM initializes
      custom.startupServices = [ "noctalia-shell.service" ];

      custom.programs = {
        # setup blur for hyprland
        hyprland.settings = {
          layerrule = [
            "match:namespace noctalia-background-.*$, ignore_alpha 0.5, blur on"
          ];
        };

        print-config = {
          noctalia = /* sh */ ''noctalia-shell ipc call state all | ${lib.getExe pkgs.jq} -S ".settings"'';
        };
      };

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
