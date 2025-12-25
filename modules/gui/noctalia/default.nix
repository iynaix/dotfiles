{ inputs, lib, ... }:
{
  flake.nixosModules.wm =
    let
      noctaliaSettings = import ./_settings.nix;
    in
    { pkgs, ... }:
    {
      services.noctalia-shell = {
        enable = true;
        package = inputs.noctalia.packages.${pkgs.stdenv.hostPlatform.system}.default.overrideAttrs {
          patches = [ ./face-aware-crop.patch ];
        };
        # TODO: set custom target for niri / mango?
        target = "hyprland-session.target";
      };

      environment.systemPackages = with pkgs; [
        matugen
      ];

      hj.xdg.config.files = {
        "noctalia/settings.json".text = lib.strings.toJSON noctaliaSettings;
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
