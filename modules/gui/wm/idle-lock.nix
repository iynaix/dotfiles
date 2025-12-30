{ lib, ... }:
let
  inherit (lib)
    assertMsg
    getExe
    mkEnableOption
    mkIf
    versionOlder
    ;
in
{
  flake.nixosModules.core =
    { isLaptop, self, ... }:
    {
      options.custom = {
        lock.enable = mkEnableOption "screen locking of host" // {
          default = isLaptop;
        };

        programs.hypridle = {
          settings = self.lib.types.hyprlandSettingsType;
        };
      };
    };

  flake.nixosModules.wm =
    {
      config,
      isLaptop,
      pkgs,
      self,
      ...
    }:
    let
      hypridleConfText = self.lib.generators.toHyprconf {
        attrs = config.custom.programs.hypridle.settings;
        importantPrefixes = [ "$" ];
      };
      noctalia-lock = pkgs.writeShellApplication {
        name = "noctalia-lock";
        runtimeInputs = with pkgs; [
          noctalia-shell
        ];
        # to be used on laptops, so suspend as well
        text = /* sh */ ''
          noctalia-shell ipc call lockScreen lockAndSuspend
        '';
      };
      dpms-on = pkgs.writeShellApplication {
        name = "dpms-on";
        text = /* sh */ ''
          # TODO: mango?
          if [ "$XDG_CURRENT_DESKTOP" = "Hyprland" ]; then
              hyprctl dispatch dpms on
          elif [ "$XDG_CURRENT_DESKTOP" = "niri" ]; then
              niri msg action power-on-monitors
          fi
        '';
      };
      dpms-off = pkgs.writeShellApplication {
        name = "dpms-off";
        text = /* sh */ ''
          # TODO: mango?
          if [ "$XDG_CURRENT_DESKTOP" = "Hyprland" ]; then
              hyprctl dispatch dpms off
          elif [ "$XDG_CURRENT_DESKTOP" = "niri" ]; then
              niri msg action power-off-monitors
          fi
        '';
      };
      lock = pkgs.writeShellApplication {
        name = "lock";
        text =
          if config.custom.lock.enable then # sh
            (getExe noctalia-lock)
          else
            (getExe dpms-off);
      };
    in
    {
      environment.systemPackages = [
        dpms-on
        dpms-off
        lock
      ];

      # lock on idle
      custom.programs = {
        hypridle = {
          settings = {
            general = {
              ignore_dbus_inhibit = false;
              lock_cmd = "lock";
            };

            listener = [
              {
                timeout = 5 * 60;
                on-timeout = "lock";
                on-resume = "dpms-on";
              }
            ];
          };
        };

        hyprland.settings = {
          bind = [ "$mod_SHIFT_CTRL, x, exec, lock" ];

          # handle laptop lid
          bindl = mkIf isLaptop [ ",switch:Lid Switch, lock" ];
        };

        niri.settings = {
          binds = {
            "Mod+Shift+Ctrl+x".spawn = [ "lock" ];
          };

          /*
            switch-events = {
              lid-open.spawn = lockOrDpms;
            };
          */
        };

        # TODO: mango doesn't support switch events yet?
        mango.settings = {
          bind = [ "$mod+SHIFT+CTRL, x, lock" ];
        };
      };

      services.hypridle = {
        enable =
          assert (assertMsg (versionOlder pkgs.hypridle.version "0.1.8") "hypridle updated, use wrapper");
          true;

        # package =
        #   inputs.wrappers.lib.wrapPackage {
        #     inherit pkgs;
        #     package = pkgs.hypridle.overrideAttrs {
        #       src = pkgs.fetchFromGitHub {
        #         owner = "hyprwm";
        #         repo = "hypridle";
        #         rev = "f158b2fe9293f9b25f681b8e46d84674e7bc7f01";
        #         hash = "sha256-jVkY2ax7e+V+M4RwLZTJnOVTdjR5Bj10VstJuK60tl4=";
        #       };
        #     };
        #     flags = {
        #       "--config" = pkgs.writeText "hypridle.conf" hypridleConfText;
        #     };
        #     flagSeparator = "=";
        #     # patch the service file to use the wrapper
        #     filesToPatch = [ "share/systemd/user/*.service" ];
        #   };
      };

      # by default, the service uses the systemd package from the hypridle derivation,
      # so using a config file is necessary
      hj.xdg.config.files."hypr/hypridle.conf".text = hypridleConfText;
    };
}
