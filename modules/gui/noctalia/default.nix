{ inputs, lib, ... }:
let
  inherit (lib)
    getExe
    getExe'
    mkForce
    optionalString
    ;
in
{
  flake.nixosModules.wm =
    {
      config,
      isLaptop,
      pkgs,
      ...
    }:
    let
      noctaliaSettings = import ./_settings.nix { inherit lib isLaptop; };
      noctalia-shell' =
        (inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default.override {
          calendarSupport = true;
        }).overrideAttrs
          {
            patches = [ ./face-aware-crop.patch ];

            postPatch = ''
              substituteInPlace "Services/Noctalia/UpdateService.qml" \
                --replace-fail "3.8" "3.9"
            '';
          };
    in
    {
      nixpkgs.overlays = [
        (_: _prev: {
          noctalia-shell = noctalia-shell';
        })
      ];

      hj.xdg.config.files = {
        "noctalia/settings.json".text = lib.strings.toJSON noctaliaSettings;
        "noctalia/plugins.json" = {
          text = lib.strings.toJSON {
            sources = [
              {
                enabled = true;
                name = "Official Noctalia Plugins";
                url = "https://github.com/noctalia-dev/noctalia-plugins";
              }
            ];
            states = {
              projects-provider = {
                enabled = true;
              };
            };
          };
        };
        # substitute projects dir into code
        "noctalia/plugins/projects-provider".source = pkgs.runCommand "set-project-dir" { } /* sh */ ''
          cp -r ${./projects-provider} $out
              substituteInPlace $out/LauncherProvider.qml \
                --replace-fail "%PROJECT_DIR%" "/persist${config.hj.directory}/projects"
        '';
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
          # restartIfChanged = true;

          # fix runtime deps when starting noctalia-shell from systemd
          # use runtime environment, similar to hyprland
          # https://github.com/noctalia-dev/noctalia-shell/pull/418
          environment = {
            PATH = mkForce "/run/wrappers/bin:/etc/profiles/per-user/%u/bin:/nix/var/nix/profiles/default/bin:/run/current-system/sw/bin";
          };

          serviceConfig = {
            ExecStart = lib.getExe noctalia-shell';
            Restart = "on-failure";
            Environment = [
              "NOCTALIA_SETTINGS_FALLBACK=%h/.config/noctalia/gui-settings.json"
            ];
          };
        };

        # run wallpaper after noctalia-shell starts
        wallpaper = {
          wantedBy = [ "noctalia-shell.service" ];

          unitConfig = {
            Description = "Set the wallpapers";
            After = [ "noctalia-shell.service" ];
            Requires = [ "noctalia-shell.service" ];
          };

          serviceConfig = {
            Type = "oneshot";
            ExecStartPre = "${getExe' pkgs.coreutils "sleep"} 3";
            ExecStart = getExe (
              pkgs.writeShellApplication {
                name = "wallpaper-startup";
                runtimeInputs = [
                  noctalia-shell'
                  pkgs.custom.dotfiles-rs
                ];
                text = ''
                  # hide on laptop screens to save space
                  ${optionalString isLaptop "noctalia-shell ipc call bar hide"}
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

      environment.systemPackages = [ noctalia-shell' ];

      # start after WM initializes
      custom.startupServices = [ "noctalia-shell.service" ];

      custom.shell.packages = {
        noctalia-shell-reload = {
          text = /* sh */ ''
            systemctl --user restart noctalia-shell
          '';
        };
        noctalia-ipc = {
          runtimeInputs = with pkgs; [
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
            if [[ ! "$NOCTALIA_PATH" =~ "${pkgs.noctalia-shell}" ]]; then
              killall .quickshell-wrapper
              systemctl --user restart noctalia-shell
              sleep 2
            fi

            ${lib.getExe pkgs.noctalia-shell} ipc call "$@"
          '';
        };
      };

      # setup blur for hyprland
      # custom.programs.hyprland.settings = {
      #   layerrule = [
      #     ''match:namespace noctalia-background-.*$ ignore_alpha 0.5, blur on, blur_popups on''
      #     ''match:namespace noctalia-bar-.*$ ignore_alpha 0.5, blur on''
      #   ];
      # };

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
