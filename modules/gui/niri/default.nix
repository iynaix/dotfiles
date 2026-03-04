{
  inputs,
  lib,
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
      niriWrapped = inputs.wrappers.wrapperModules.niri.apply {
        inherit pkgs;
        package =
          assert lib.assertMsg (lib.versionOlder pkgs.niri.version "25.12")
            "update niri-ipc in dotfiles-rs, focal to use mainline niri-ipc";
          (lib.mkForce (
            pkgs.niri.overrideAttrs (o: rec {
              src = pkgs.fetchFromGitHub {
                owner = "niri-wm";
                repo = "niri";
                rev = "c837d944f0cc08580ee86574dd0c3a68ca9379a4";
                hash = "sha256-nSrfHwbjg8/Rfx5pqDqU8bL5IWh99MsvxfjNZYxqEFw=";
              };

              postPatch = ''
                patchShebangs resources/niri-session
                substituteInPlace resources/niri.service \
                  --replace-fail 'ExecStart=niri' "ExecStart=$out/bin/niri"
              '';

              # creating an overlay for buildRustPackage overlay (NOTE: this is an IFD)
              # https://discourse.nixos.org/t/is-it-possible-to-override-cargosha256-in-buildrustpackage/4393/3
              cargoDeps = pkgs.rustPlatform.importCargoLock {
                lockFile = "${src}/Cargo.lock";
                allowBuiltinFetchGit = true;
              };

              patches = (o.patches or [ ]) ++ [
                # unmerged PR to fix this
                # https://github.com/YaLTeR/niri/pull/3004
                ./transparent-fullscreen.patch
              ];

              doCheck = false; # faster builds
            })
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
      # the workspaces are name W1, W2, etc as simply naming them as "1", "2", etc
      # causes waybar to just coerce them back into numbers, so workspaces end up being a
      # weird sequence of numbers and indexes on any monitor that isn't the first, e.g.
      # 6 7 3
      programs.niri = {
        enable = true;
        package = niriWrapped.wrapper;
        useNautilus = false;
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
          niri = /* sh */ ''cat "${niriWrapped.env."NIRI_CONFIG"}"'';
        };
      };
    };
}
