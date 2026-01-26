{ lib, ... }:
{
  flake.nixosModules.wm =
    { pkgs, ... }:
    let
      extraOptionsStr = lib.escapeShellArgs [
        "-max-dedupe-search"
        "10"
        "-max-items"
        "500"
      ];
    in
    {
      environment.systemPackages = with pkgs; [
        # clipboard history
        cliphist
        wl-clipboard
      ];

      # implementation of cliphist services from home-manager:
      # https://github.com/nix-community/home-manager/blob/master/modules/services/cliphist.nix
      systemd.user.services.cliphist = {
        wantedBy = [ "graphical-session.target" ];

        unitConfig = {
          Description = "Clipboard management daemon";
          PartOf = [ "graphical-session.target" ];
          After = [ "graphical-session.target" ];
        };

        serviceConfig = {
          Type = "simple";
          ExecStart = "${lib.getExe' pkgs.wl-clipboard "wl-paste"} --watch ${lib.getExe pkgs.cliphist} ${extraOptionsStr} store";
          Restart = "on-failure";
        };
      };

      systemd.user.services.cliphist-images = {
        wantedBy = [ "graphical-session.target" ];

        unitConfig = {
          Description = "Clipboard management daemon - images";
          PartOf = [ "graphical-session.target" ];
          After = [ "graphical-session.target" ];
        };

        serviceConfig = {
          Type = "simple";
          ExecStart = "${lib.getExe' pkgs.wl-clipboard "wl-paste"} --type image --watch ${lib.getExe pkgs.cliphist} ${extraOptionsStr} store";
          Restart = "on-failure";
        };
      };
    };
}
