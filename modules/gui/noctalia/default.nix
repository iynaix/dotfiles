{ inputs, lib, ... }:
{
  flake.nixosModules.wm =
    { isLaptop, pkgs, ... }:
    let
      inherit (lib) getExe getExe' mkForce;
      noctaliaSettings = import ./_settings.nix { inherit lib isLaptop; };
      noctalia-shell' =
        (inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default.override {
          calendarSupport = true;
        }).overrideAttrs
          {
            patches = [ ./face-aware-crop.patch ];
          };
    in
    # don't use the systemd service, it's very buggy :(
    {
      nixpkgs.overlays = [
        (_: _prev: {
          noctalia-shell = noctalia-shell';
        })
      ];

      hj.xdg.config.files = {
        "noctalia/settings.json".text = lib.strings.toJSON noctaliaSettings;
      };

      # custom noctalia service that starts after the WM is ready
      systemd.user.services = {
        noctalia-shell = {
          description = "Noctalia Shell - Wayland desktop shell";
          documentation = [ "https://docs.noctalia.dev/docs" ];
          partOf = [ "graphical-session.target" ];
          restartTriggers = [ noctalia-shell' ];

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
            PartOf = [ "graphical-session.target" ];
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
                text = ''wallpaper'';
              }
            );
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
      };

      custom.persist = {
        home = {
          directories = [
            ".config/noctalia"
          ];

          # mainly so the new version popup doesn't reappear
          cache.directories = [
            ".cache/noctalia"
          ];
        };
      };
    };
}
