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
        package =
          let
            source = (pkgs.callPackage ../../../_sources/generated.nix { }).niri;
          in
          (self.wrapperModules.niri.apply {
            inherit pkgs;
            package = pkgs.niri.overrideAttrs (
              o:
              (
                source
                // {
                  inherit (o) version;

                  patches =
                    (o.patches or [ ])
                    # not compatible with blur patch
                    ++ [
                      # fix fullscreen windows have a black background
                      # https://github.com/YaLTeR/niri/discussions/1399#discussioncomment-12745734
                      ./transparent-fullscreen.patch
                      # increase maximum shadow spread to be able to fake dimaround on ultrawide
                      # see: https://github.com/YaLTeR/niri/discussions/1806
                      ./larger-shadow-spread.patch
                    ];

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
          }).wrapper;
        useNautilus = false;
      };

      xdg.portal = {
        config = {
          niri = {
            "org.freedesktop.impl.portal.FileChooser" = "gtk";
          };
        };
      };

      custom = {
        programs = {

          ghostty.extraSettings = {
            background-opacity = mkForce 0.95;
          };

          # waybar config for niri
          waybar.config = {
            "niri/workspaces" = {
              format = "{icon}";
              format-icons = {
                # named workspaces
                "W1" = "1";
                "W2" = "2";
                "W3" = "3";
                "W4" = "4";
                "W5" = "5";
                "W6" = "6";
                "W7" = "7";
                "W8" = "8";
                "W9" = "9";
                "W10" = "10";
                # non named workspaces
                default = "";
              };
            };
          };
        };
      };
    };
}
