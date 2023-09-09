{
  config,
  host,
  inputs,
  lib,
  pkgs,
  ...
}: let
  cfg = config.iynaix-nixos.hyprland;
in {
  config = lib.mkIf cfg.enable {
    services.xserver.desktopManager.gnome.enable = lib.mkForce false;
    services.xserver.displayManager.lightdm.enable = lib.mkForce false;
    # services.xserver.displayManager.sddm.enable = lib.mkForce true;

    # locking with swaylock
    security.pam.services.swaylock = {
      text = "auth include login";
    };

    programs.hyprland.enable = true;

    hm.wayland.windowManager.hyprland = lib.mkMerge [
      {
        enable = true;
        package = inputs.hyprland.packages.${pkgs.system}.hyprland;
      }
      (lib.mkIf (cfg.plugin == "hyprnstack") {
        settings.general.layout = lib.mkForce "nstack";

        # plugins = ["/persist/home/iynaix/projects/hyprNStack/result/lib/libhyprNStack.so"];
        plugins = [pkgs.iynaix.hyprNStack];

        # use hyprNStack plugin, the home-manager options do not seem to emit the plugin section
        extraConfig = ''
          plugin {
            nstack {
              layout {
                orientation=left
                new_is_master=0
                stacks=${toString (
            if host == "desktop"
            then 3
            else 2
          )}
                # disable smart gaps
                no_gaps_when_only=0
                # master is the same size as the stacks
                mfact=0
              }
            }
          }
        '';
      })
    ];

    environment.systemPackages = [
      inputs.hyprland.packages.${pkgs.system}.xdg-desktop-portal-hyprland
    ];
  };
}
