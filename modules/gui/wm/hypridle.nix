{
  flake.nixosModules.core =
    { self, ... }:
    {
      options.custom = {
        programs.hypridle = {
          settings = self.lib.types.hyprlandSettingsType;
        };
      };
    };

  flake.nixosModules.wm =
    {
      config,
      lib,
      pkgs,
      self,
      ...
    }:
    let
      inherit (lib) assertMsg getExe versionOlder;
      inherit (config.custom) wm;
      dpmsOff =
        if wm == "hyprland" then
          "hyprctl dispatch dpms off"
        else if wm == "niri" then
          "${getExe config.programs.niri.package} msg action power-off-monitors"
        else
          "";
      dpmsOn =
        if wm == "hyprland" then
          "hyprctl dispatch dpms on"
        else if wm == "niri" then
          "${getExe config.programs.niri.package} msg action power-on-monitors"
        else
          "";
      hypridleConfText = self.lib.generators.toHyprconf {
        attrs = config.custom.programs.hypridle.settings;
        importantPrefixes = [ "$" ];
      };
    in
    {
      custom = {
        programs.hypridle.settings = {
          general = {
            ignore_dbus_inhibit = false;
          };

          listener = [
            {
              timeout = 5 * 60;
              on-timeout = dpmsOff;
              on-resume = dpmsOn;
            }
          ];
        };
      };

      # NOTE: screen lock on idle is handled in lock.nix
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
