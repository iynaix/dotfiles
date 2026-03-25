{
  inputs,
  lib,
  self,
  ...
}:
{
  flake.modules.nixos.core =
    { pkgs, ... }:
    {
      options.custom = {
        programs.niri = {
          settings = lib.mkOption {
            type = lib.types.submodule {
              freeformType = (pkgs.formats.json { }).type;
              # strings don't merge by default
              options.extraConfig = lib.mkOption {
                type = lib.types.lines;
                default = "";
                description = "Additional configuration lines.";
              };
            };
            description = "Niri settings, see https://github.com/Lassulus/wrappers/blob/main/modules/niri/module.nix for available options";
          };
        };
      };
    };

  flake.modules.nixos.wm =
    { config, pkgs, ... }:
    let
      source = (self.libCustom.nvFetcherSources pkgs).niri;
      niriWrapped = inputs.wrappers.wrapperModules.niri.apply {
        inherit pkgs;
        package =
          assert lib.assertMsg (lib.versionOlder pkgs.niri.version "25.12")
            "update niri-ipc in dotfiles-rs, focal to use mainline niri-ipc";
          (lib.mkForce (
            pkgs.niri.overrideAttrs (
              o:
              (
                source
                // {
                  inherit (o) version; # needed for annoying version check

                  postPatch = ''
                    patchShebangs resources/niri-session
                    substituteInPlace resources/niri.service \
                      --replace-fail 'ExecStart=niri' "ExecStart=$out/bin/niri"
                  '';

                  # creating an overlay for buildRustPackage overlay (NOTE: this is an IFD)
                  # https://discourse.nixos.org/t/is-it-possible-to-override-cargosha256-in-buildrustpackage/4393/3
                  cargoDeps = pkgs.rustPlatform.importCargoLock {
                    lockFile = "${source.src}/Cargo.lock";
                    allowBuiltinFetchGit = true;
                  };

                  patches = (o.patches or [ ]) ++ [
                    # unmerged PR to fix this
                    # https://github.com/YaLTeR/niri/pull/3004
                    ./transparent-fullscreen.patch
                  ];

                  doCheck = false; # faster builds
                }
              )
            )
          ));

        inherit (config.custom.programs.niri) settings;
      };
    in
    {
      environment = {
        shellAliases = {
          niri-log = ''journalctl --user -u niri --no-hostname -o cat | awk '{$1=""; print $0}' | sed 's/^ *//' | sed 's/\x1b[[0-9;]*m//g' '';
        };
      };

      # NOTE: named workspaces are used, because dynamic workspaces are just... urgh
      programs.niri = {
        enable = true;
        package = niriWrapped.wrapper;
        useNautilus = false;
      };

      # restart niri with new settings on rebuild
      system.userActivationScripts = {
        niri-reload-config = {
          text = lib.getExe (
            pkgs.writeShellApplication {
              name = "niri-reload-config";
              runtimeInputs = [
                config.programs.niri.package
                pkgs.procps
              ];
              text = ''
                if pgrep -x "niri" > /dev/null; then
                  niri msg action load-config-file --path "${niriWrapped.env."NIRI_CONFIG"}"
                fi
              '';
            }
          );
        };
      };

      xdg.portal = {
        config = {
          niri = {
            "org.freedesktop.impl.portal.FileChooser" = "gtk";
          };
        };
      };

      custom.programs = {
        ghostty.extraSettings = {
          background-opacity = lib.mkForce 0.95;
        };

        print-config = {
          # use cat as kdlfmt tries to write the file in the nix store
          niri = /* sh */ ''cat "${niriWrapped.env."NIRI_CONFIG"}" | ${lib.getExe pkgs.kdlfmt} format - | moor --lang kdl'';
        };
      };
    };
}
