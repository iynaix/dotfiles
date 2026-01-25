{ lib, self, ... }:
{
  flake.nixosModules.wm =
    { config, pkgs, ... }:
    let
      # source = (pkgs.callPackage ../../../_sources/generated.nix { }).niri;
      niriWrapped = self.wrapperModules.niri.apply {
        inherit pkgs;
        package = pkgs.niri.overrideAttrs (o: {
          patches = (o.patches or [ ]) ++ [
            (pkgs.fetchpatch {
              url = "https://github.com/YaLTeR/niri/commit/7a237e519c69ec493851ffac169abb3aa917a7b3.patch";
              hash = "sha256-svv8YOrDR45qHbKM8GCAp5tkJbFBefE8z1GftxyOZlA=";
            })
            # unmerged PR to fix this
            # https://github.com/YaLTeR/niri/pull/3004
            ./transparent-fullscreen.patch
          ];

          doCheck = false; # faster builds
        });

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
