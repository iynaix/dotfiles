{ lib, ... }:
let
  inherit (lib) mkForce;
in
{
  flake.nixosModules.wm =
    {
      config,
      pkgs,
      self,
      ...
    }:
    let
      source = (pkgs.callPackage ../../../_sources/generated.nix { }).niri;
      niriWrapped = self.wrapperModules.niri.apply {
        inherit pkgs;
        package = pkgs.niri.overrideAttrs (
          o:
          (
            source
            // {
              inherit (o) version;

              # patches =
              #   (o.patches or [ ])
              #   # not compatible with blur patch
              #   ++ [
              #     # fix fullscreen windows have a black background
              #     # https://github.com/YaLTeR/niri/discussions/1399#discussioncomment-12745734
              #     # unmerged PR to fix this
              #     # https://github.com/YaLTeR/niri/pull/3004
              #     ./transparent-fullscreen.patch
              #   ];

              # https://github.com/YaLTeR/niri/pull/3190
              postPatch = ''
                patchShebangs resources/niri-session
                substituteInPlace resources/niri.service \
                  --replace-fail 'ExecStart=niri' "ExecStart=$out/bin/niri"
              '';

              # creating an overlay for buildRustPackage overlay
              # https://discourse.nixos.org/t/is-it-possible-to-override-cargosha256-in-buildrustpackage/4393/3
              cargoDeps = pkgs.rustPlatform.importCargoLock {
                lockFile = source.src + "/Cargo.lock";
                allowBuiltinFetchGit = true;
              };

              doCheck = false; # faster builds
            }
          )
        );

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
          background-opacity = mkForce 0.95;
        };

        print-config = {
          niri = /* sh */ ''cat "${niriWrapped.env."NIRI_CONFIG"}"'';
        };
      };
    };
}
