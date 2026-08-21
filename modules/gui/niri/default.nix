{
  tags = [ "wm" ];

  config =
    {
      config,
      inputs,
      lib,
      pkgs,
      ...
    }:
    let
      niri' = inputs.wrappers.wrappers.niri.wrap {
        inherit pkgs;
        package = lib.mkForce (
          pkgs.niri.overrideAttrs (o: {
            doInstallCheck = false; # disable annoying version check

            patches = (o.patches or [ ]) ++ [
              # unmerged PR to fix this
              # https://github.com/YaLTeR/niri/pull/3004
              ./transparent-fullscreen.patch
            ];

            doCheck = false; # faster builds
          })
        );

        inherit (config.custom.programs.niri) settings;
      };
    in
    {
      options.custom = {
        programs.niri = {
          # use the option from the niri wrapper module
          inherit (inputs.wrappers.wrappers.niri.wrapperOptions) settings;
        };
      };

      config = {
        environment = {
          shellAliases = {
            niri-log = ''journalctl --user -u niri --no-hostname -o cat | awk '{$1=""; print $0}' | sed 's/^ *//' | sed 's/\x1b[[0-9;]*m//g' '';
          };
        };

        programs.niri = {
          enable = true;
          package = niri';
          useNautilus = false;
        };

        programs.uwsm.waylandCompositors = {
          niri = {
            prettyName = "Niri";
            comment = "Niri compositor managed by UWSM";
            binPath = "/run/current-system/sw/bin/niri-session";
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
          print-config = {
            # use cat as kdlfmt tries to write the file in the nix store
            niri = /* sh */ ''cat "${niri'.configuration.constructFiles.generatedConfig.outPath}" "${config.hj.xdg.config.directory}/niri/config.kdl" "${config.hj.xdg.config.directory}/niri/noctalia.kdl" | moor --lang kdl'';
          };
        };
      };
    };
}
