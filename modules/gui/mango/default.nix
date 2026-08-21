{
  tags = [ "wm" ];

  config =
    {
      config,
      inputs,
      lib,
      libCustom,
      pkgs,
      tags,
      ...
    }:
    {
      options.custom = {
        programs.mango = {
          # use the option from the mango wrapper module
          inherit (inputs.wrappers.wrappers.mangowc.wrapperOptions) settings;
        };
      };

      config =
        let
          # use ALT when used in a VM
          mkMangoBind = lib.replaceString "$mod" (if (builtins.elem "vm" tags) then "ALT" else "SUPER");
          mangoSettings = config.custom.programs.mango.settings;
          mango' = inputs.wrappers.wrappers.mangowc.wrap {
            inherit pkgs;
            package = pkgs.mango.overrideAttrs (
              o:
              (libCustom.nvFetcherSources pkgs).mango
              // {
                patches = (o.patches or [ ]) ++ [
                  # adds niri inspired atstartup rule:
                  # https://github.com/mangowm/mango/pull/654
                  (pkgs.fetchurl {
                    url = "https://github.com/mangowm/mango/commit/46a5d4445b1e5f4e27a340f47ec31a55ca922ba9.patch";
                    hash = "sha256-flyNWQN+AREpzsG9rh5ndlNYISYLI/gKdmGXgYpdshQ=";
                  })
                ];
              }
            );

            topPrefixes = [ "monitorrule" ];
            bottomPrefixes = [
              "source"
              "source-optional"
            ];
            settings = mangoSettings // {
              bind = map mkMangoBind (mangoSettings.bind or [ ]);
              mousebind = map mkMangoBind (mangoSettings.mousebind or [ ]);
              source-optional = "${config.hj.xdg.config.directory}/mango/noctalia.conf";
            };
          };
        in
        {
          programs.mango = {
            enable = true;
            package = mango';
          };

          # expose reload service to systemd
          # https://github.com/BirdeeHub/nix-wrapper-modules/pull/577#issuecomment-5209190628
          systemd.packages = [ config.programs.mango.package ];

          programs.uwsm.waylandCompositors = {
            mango = {
              prettyName = "Mango";
              comment = "Mango compositor managed by UWSM";
              binPath = "/run/current-system/sw/bin/mango";
            };
          };

          custom.programs = {
            print-config = {
              mango = /* sh */ ''cat "${config.programs.mango.package.configuration.constructFiles.generatedConfig.outPath}" "${config.hj.xdg.config.directory}/mango/noctalia.conf" | moor'';
            };
          };
        };
    };
}
