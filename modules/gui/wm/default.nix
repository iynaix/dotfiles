{
  flake.modules.nixos.wm =
    { pkgs, ... }:
    {
      environment = {
        sessionVariables = {
          NIXOS_OZONE_WL = "1";
          QT_QPA_PLATFORM = "wayland";
        };
      };

      xdg.portal = {
        enable = true;
        config = {
          common.default = [ "gnome" ];
          obs.default = [ "gnome" ];
        };
        extraPortals = [ pkgs.xdg-desktop-portal-gtk ];
      };

      hj.files.".face".source = ../../avatar.png;

      custom = {
        programs.print-config = {
          wm = /* sh */ ''
            if [ "$XDG_CURRENT_DESKTOP" == "Hyprland" ]; then
                hyprland-config
            elif [ "$XDG_CURRENT_DESKTOP" == "niri" ]; then
                niri-config
            elif [ "$XDG_CURRENT_DESKTOP" == "mango" ]; then
                mango-config
            fi
          '';
        };
      };
    };
}
