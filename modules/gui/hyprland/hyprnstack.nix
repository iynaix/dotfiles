{ lib, self, ... }:
{
  perSystem =
    { pkgs, ... }:
    let
      drv =
        {
          lib,
          gcc15Stdenv,
          hyprland,
          fetchFromGitHub,
        }:
        gcc15Stdenv.mkDerivation (finalAttrs: {
          pname = "hyprNStack";
          version = "cbffba31ed820e2fbad6cb21ad0b15a051a9a4e7";
          src = fetchFromGitHub {
            owner = "zakk4223";
            repo = "hyprNstack";
            rev = finalAttrs.version;
            hash = "sha256-Cf0TFPrr+XLHRhbRF+zd2/YHgtS2KXskIFv0BQiYjLc=";
          };

          inherit (hyprland) nativeBuildInputs;

          buildInputs = [ hyprland.dev ] ++ hyprland.buildInputs;

          # Skip meson phases
          configurePhase = "true";
          mesonConfigurePhase = "true";
          mesonBuildPhase = "true";
          mesonInstallPhase = "true";

          buildPhase = /* sh */ ''
            make all
          '';

          installPhase = /* sh */ ''
            mkdir -p $out/lib
            cp nstackLayoutPlugin.so $out/lib/libhyprNStack.so
          '';

          meta = {
            homepage = "https://github.com/zakk4223/hyprNStack";
            description = "Hyprland HyprNStack Plugin";
            maintainers = [ lib.maintainers.iynaix ];
            platforms = lib.platforms.linux;
          };
        });
    in
    {
      packages.hyprnstack = pkgs.callPackage drv { };
    };

  flake.nixosModules.wm =
    { config, pkgs, ... }:
    {
      custom.programs.hyprland =
        if config.custom.programs.hyprnstack.enable then
          {
            plugins = [ self.packages.${pkgs.stdenv.hostPlatform.system}.hyprnstack ];

            settings = {
              general.layout = "nstack";
              "plugin:nstack" = {
                layout = {
                  new_is_master = 0;
                  # disable smart gaps
                  no_gaps_when_only = 0;
                  # master is the same size as the stacks
                  mfact = 0.0;
                };
              };

              # add rules for vertical displays and number of stacks
              workspace = lib.mkAfter (
                self.libCustom.mapWorkspaces (
                  { monitor, workspace, ... }:
                  let
                    isUltrawide = builtins.div (monitor.width * 1.0) monitor.height > builtins.div 16.0 9;
                    stacks = if (monitor.isVertical || isUltrawide) then 3 else 2;
                  in
                  lib.concatStringsSep "," (
                    [
                      workspace
                      "persistent:true"
                      "layoutopt:nstack-stacks:${toString stacks}"
                      "layoutopt:nstack-orientation:${if monitor.isVertical then "top" else "left"}"
                    ]
                    ++ lib.optionals (!isUltrawide) [ "layoutopt:nstack-mfact:0.0" ]
                  )
                ) config.custom.hardware.monitors
              );
            };
          }

        # handle workspace orientation without hyprnstack
        else
          {
            settings.workspace = lib.mkAfter (
              self.libCustom.mapWorkspaces (
                { monitor, workspace, ... }:
                "${workspace},persistent:true,layoutopt:orientation:${if monitor.isVertical then "top" else "left"}"
              ) config.custom.hardware.monitors
            );
          };
    };
}
