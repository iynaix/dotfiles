{ pkgs, user, lib, config, host, ... }: {
  home-manager.users.${user} = {
    services.picom = {
      enable = true;
      shadow = false;
      fadeDelta = 4;
      inactiveOpacity = 1;
      opacityRules = [
        "100:name *= 'NVIM' && focused"
        "100:window_type = 'popup_menu'"
        # "95:name *= 'NVIM'"
        "90:class_g = 'Alacritty'"
        "90:class_g = 'kitty'"
        # "70:class_g = 'Bspwm' && class_i = 'presel_feedback'"
      ];
      backend = "glx";
      settings = {
        blur-method = "dual_kawase";
        blur-size = 12;
        blur-strength = 10;
        blur-background-exclude = [
          # "window_type = 'dock'"
          "window_type = 'desktop'"
          "window_type = 'tooltip'"
          "window_type = 'dropdown_menu'"
          "window_type = 'popup_menu'"
          "class_g = 'slop'" # do not blur desktop while capturing screenshots
          "_GTK_FRAME_EXTENTS@:c"
        ];
        invert-color-include = [ "class_g = 'MongoDB Compass'" ];
        glx-no-stencil = true;
      };
    };
  };
}
